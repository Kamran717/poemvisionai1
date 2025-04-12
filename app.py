import os
import logging
from flask import Flask, render_template, request, jsonify, session
import base64
import uuid
import json
import string
import random
import re
from utils.image_analyzer import analyze_image
from utils.poem_generator import generate_poem
from utils.image_manipulator import create_framed_image
from models import db, Creation

# Set up logging first so we can use it everywhere
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.secret_key = os.environ.get("SESSION_SECRET", "dev-secret-key")

# Set up database with connection pooling and retry settings
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
    "pool_pre_ping": True,  # Check if connection is alive before using it
    "pool_recycle": 280,    # Recycle connections after 280 seconds
    "pool_timeout": 30,     # Timeout waiting for a connection from pool
    "max_overflow": 15,     # Allow up to 15 connections beyond pool_size
    "pool_size": 10,        # Keep up to 10 connections in the pool
    "connect_args": {"connect_timeout": 10}  # Connection timeout in seconds
}
db.init_app(app)

# Create all database tables if they don't exist
try:
    with app.app_context():
        db.create_all()
        logger.info("Database tables created successfully")
except Exception as e:
    logger.error(f"Error creating database tables: {str(e)}", exc_info=True)

# Routes
@app.route('/')
def index():
    """Render the main page of the application."""
    return render_template('index.html')

@app.route('/analyze-image', methods=['POST'])
def analyze_image_route():
    """Analyze the uploaded image using Google Cloud Vision AI."""
    try:
        # Log request content type to help debug
        logger.info(f"Request content type: {request.content_type}")
        
        # Image can be in form data or direct JSON post with base64
        image_file = None
        image_data = None
        file_size = 0
        
        if request.content_type and 'multipart/form-data' in request.content_type:
            # Handle form uploads
            if 'image' not in request.files:
                logger.error("No image file in multipart request")
                return jsonify({'error': 'No image uploaded. Please try again.'}), 400
            
            image_file = request.files['image']
            
            if image_file.filename == '':
                logger.error("Empty filename in uploaded file")
                return jsonify({'error': 'No image selected. Please try again.'}), 400
            
            # Log received file type
            logger.info(f"Received image type: {image_file.content_type}")
                
            # Check file size - limit to 5MB
            image_file.seek(0, os.SEEK_END)
            file_size = image_file.tell()
            logger.info(f"Upload file size: {file_size/1024/1024:.2f}MB")
            
            # Reset file pointer for processing
            image_file.seek(0)
            
            # Read image data
            image_data = base64.b64encode(image_file.read()).decode('utf-8')
            
        elif request.content_type and 'application/json' in request.content_type:
            # Handle direct JSON posts with base64 data
            try:
                json_data = request.get_json()
                
                if not json_data or 'image' not in json_data:
                    logger.error("No image data in JSON request")
                    return jsonify({'error': 'No image data provided. Please try again.'}), 400
                
                # Get the base64 image string, removing data URL prefix if present
                base64_image = json_data['image']
                if ',' in base64_image:
                    base64_image = base64_image.split(',')[1]
                
                # Check size of base64 data
                estimated_size = len(base64_image) * 3 / 4  # Rough estimation
                file_size = estimated_size
                logger.info(f"Estimated upload size from base64: {estimated_size/1024/1024:.2f}MB")
                
                if estimated_size > 5 * 1024 * 1024:  # 5MB limit
                    return jsonify({'error': 'Image size exceeds the 5MB limit. Please choose a smaller image.'}), 400
                
                # Store the base64 data
                image_data = base64_image
                
                # Create a file-like object for analysis
                import io
                image_bytes = base64.b64decode(base64_image)
                image_file = io.BytesIO(image_bytes)
                # Add a placeholder filename attribute for logging
                image_file.filename = "mobile_upload.jpg"
                
            except Exception as e:
                logger.error(f"Error processing JSON image data: {str(e)}", exc_info=True)
                return jsonify({'error': 'Invalid image data. Please try again.'}), 400
        else:
            logger.error(f"Unsupported content type: {request.content_type}")
            return jsonify({'error': 'Unsupported upload method. Please try again.'}), 400
        
        # Check file size - limit to 5MB (final check)
        if file_size > 5 * 1024 * 1024:  # 5MB limit
            return jsonify({'error': 'Image size exceeds the 5MB limit. Please choose a smaller image.'}), 400
        
        # Generate a shorter unique ID for this analysis
        analysis_id = str(uuid.uuid4()).split('-')[0]  # Just use the first part of the UUID
        
        # Reset file pointer and read image data
        image_file.seek(0)
        
        # Some mobile browsers may send strange content types
        # Store original data regardless
        image_data = base64.b64encode(image_file.read()).decode('utf-8')
        
        # Analyze the image using Google Cloud Vision AI
        image_file.seek(0)  # Reset the file pointer again
        logger.info(f"Analyzing image: {image_file.filename} ({file_size/1024:.1f} KB)")
        
        try:
            # Get raw analysis results from Google Vision API
            analysis_results = analyze_image(image_file)
            
            # Check if we got valid analysis results
            if not analysis_results or '_error' in analysis_results:
                error_msg = analysis_results.get('_error', 'Unknown error during image analysis')
                logger.error(f"Image analysis failed: {error_msg}")
                return jsonify({'error': f'Error analyzing image: {error_msg}'}), 500
            
            # Clean up and deduplicate the analysis results to avoid redundant terms
            analysis_results = deduplicate_elements(analysis_results)
                
        except Exception as analysis_error:
            logger.error(f"Exception during image analysis: {str(analysis_error)}", exc_info=True)
            return jsonify({'error': 'Error analyzing image. Please try again with a different image.'}), 500
        
        # Create a temporary creation in the database with retry mechanism
        max_retries = 3
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                # Create a new session for each attempt to avoid stale connections
                db.session.close()
                
                temp_creation = Creation(
                    image_data=image_data,
                    analysis_results=analysis_results,
                    share_code=f"temp{analysis_id}"  # Shorter share_code
                )
                db.session.add(temp_creation)
                db.session.commit()
                
                # Store just the ID in the session
                session[f'temp_creation_id_{analysis_id}'] = temp_creation.id
                
                return jsonify({
                    'success': True,
                    'analysisId': analysis_id,
                    'results': analysis_results
                })
                
            except Exception as db_error:
                retry_count += 1
                logger.warning(f"Database error (attempt {retry_count}/{max_retries}): {str(db_error)}")
                
                # Roll back the failed transaction
                db.session.rollback()
                
                if retry_count >= max_retries:
                    logger.error(f"Database error after {max_retries} attempts: {str(db_error)}", exc_info=True)
                    return jsonify({'error': 'Error saving analysis results. Please try again with a smaller image.'}), 500
                
                # Wait briefly before retrying (exponential backoff)
                import time
                time.sleep(0.5 * retry_count)
    
    except Exception as e:
        logger.error(f"Unexpected error analyzing image: {str(e)}", exc_info=True)
        return jsonify({'error': 'An unexpected error occurred. Please try again.'}), 500

@app.route('/generate-poem', methods=['POST'])
def generate_poem_route():
    """Generate a poem based on image analysis and user preferences."""
    try:
        data = request.json
        analysis_id = data.get('analysisId')
        
        if not analysis_id or f'temp_creation_id_{analysis_id}' not in session:
            return jsonify({'error': 'Invalid or expired analysis ID'}), 400
        
        # Get the temporary creation from the database
        temp_creation_id = session[f'temp_creation_id_{analysis_id}']
        temp_creation = Creation.query.get(temp_creation_id)
        
        if not temp_creation:
            return jsonify({'error': 'Analysis data not found'}), 400
        
        # Get analysis results from the database
        analysis_results = temp_creation.analysis_results
        
        # Get user preferences from the request
        poem_type = data.get('poemType', 'free verse')
        emphasis = data.get('emphasis', [])
        
        # Get custom prompt info if provided
        custom_prompt = data.get('customPrompt', {})
        custom_terms = custom_prompt.get('terms', '')
        custom_category = custom_prompt.get('category', '')
        
        # Generate the poem using the LLM with custom prompt if provided
        if custom_terms:
            # Pass the custom prompt data to the poem generator
            poem = generate_poem(analysis_results, poem_type, emphasis, custom_terms=custom_terms, custom_category=custom_category)
        else:
            # Generate poem without custom prompt
            poem = generate_poem(analysis_results, poem_type, emphasis)
        
        # Update the temporary creation with the poem
        temp_creation.poem_text = poem
        temp_creation.poem_type = poem_type
        temp_creation.emphasis = emphasis
        db.session.commit()
        
        return jsonify({
            'success': True,
            'poem': poem
        })
    
    except Exception as e:
        logger.error(f"Error generating poem: {str(e)}", exc_info=True)
        return jsonify({'error': f'Failed to generate poem: {str(e)}'}), 500

@app.route('/create-final-image', methods=['POST'])
def create_final_image_route():
    """Create the final framed image with the poem."""
    try:
        data = request.json
        analysis_id = data.get('analysisId')
        
        if not analysis_id or f'temp_creation_id_{analysis_id}' not in session:
            return jsonify({'error': 'Invalid or expired analysis ID'}), 400
        
        # Get the temporary creation from the database
        temp_creation_id = session[f'temp_creation_id_{analysis_id}']
        temp_creation = Creation.query.get(temp_creation_id)
        
        if not temp_creation or not temp_creation.image_data or not temp_creation.poem_text:
            return jsonify({'error': 'Image or poem data not found'}), 400
        
        # Get the frame selection from the request
        frame_style = data.get('frameStyle', 'classic')
        
        # Create the framed image with the poem
        final_image = create_framed_image(
            base64.b64decode(temp_creation.image_data), 
            temp_creation.poem_text, 
            frame_style
        )
        
        # Convert the final image to base64 for sending to the client
        final_image_base64 = base64.b64encode(final_image).decode('utf-8')
        
        # Generate a unique share code
        share_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))
        
        # Create the final creation by updating the temporary one
        temp_creation.frame_style = frame_style
        temp_creation.final_image_data = final_image_base64
        temp_creation.share_code = share_code  # Replace the temp share code with a permanent one
        db.session.commit()
        
        return jsonify({
            'success': True,
            'finalImage': final_image_base64,
            'shareCode': share_code,
            'creationId': temp_creation.id
        })
    
    except Exception as e:
        logger.error(f"Error creating final image: {str(e)}", exc_info=True)
        return jsonify({'error': f'Failed to create final image: {str(e)}'}), 500

@app.route('/shared/<share_code>')
def view_shared_creation(share_code):
    """View a shared creation by its share code."""
    try:
        # Look up the creation in the database
        creation = Creation.query.filter_by(share_code=share_code).first()
        
        if not creation:
            return render_template('error.html', message="Creation not found or no longer available"), 404
        
        # Render the shared creation template
        return render_template('shared.html', creation=creation)
    
    except Exception as e:
        logger.error(f"Error viewing shared creation: {str(e)}", exc_info=True)
        return render_template('error.html', message="An error occurred while loading this creation"), 500

@app.route('/gallery')
def gallery():
    """View a gallery of recent creations."""
    try:
        # Get the most recent 20 creations
        creations = Creation.query.order_by(Creation.created_at.desc()).limit(20).all()
        
        return render_template('gallery.html', creations=creations)
    
    except Exception as e:
        logger.error(f"Error loading gallery: {str(e)}", exc_info=True)
        return render_template('error.html', message="An error occurred while loading the gallery"), 500

# Helper function to deduplicate and simplify elements for emphasis
def deduplicate_elements(analysis_results):
    """
    Clean up analysis results to remove redundant and similar terms.
    
    Args:
        analysis_results (dict): The analysis results from Google Vision AI
        
    Returns:
        dict: Modified analysis results with cleaned lists
    """
    if not analysis_results:
        return analysis_results
    
    # Copy the results to avoid modifying the original
    results = analysis_results.copy()
    
    # Create a mapping of similar terms to normalize them
    term_mapping = {
        # Transportation/vehicles
        'watercraft': 'boat', 'yacht': 'boat', 'superyacht': 'boat', 'motorboat': 'boat',
        'naval architecture': 'boat', 'sailboat': 'boat', 'ship': 'boat',
        'boats and boating--equipment and supplies': 'boat equipment',
        'automobile': 'car', 'vehicle': 'car', 'motor vehicle': 'car',
        
        # Clothing
        'miniskirt': 'skirt', 'pants': 'clothing', 'jeans': 'clothing',
        'shirt': 'clothing', 't-shirt': 'clothing', 'jacket': 'clothing',
        'outerwear': 'clothing', 'dress': 'clothing', 'hat': 'headwear',
        'cap': 'headwear', 'footwear': 'shoes', 'sneakers': 'shoes',
        
        # Animals
        'puppy': 'dog', 'canine': 'dog', 'kitten': 'cat', 'feline': 'cat',
        
        # Nature
        'flower': 'flowers', 'tree': 'trees', 'plant': 'plants',
        'cloud': 'sky', 'sunset': 'sky', 'sunrise': 'sky',
        
        # Activities
        'recreation': 'leisure', 'vacation': 'leisure', 'travel': 'leisure',
        'trip': 'journey', 'tour': 'journey',
        
        # Emotions
        'joy': 'happiness', 'smile': 'happiness', 'happy': 'happiness',
        'sorrow': 'sadness', 'sad': 'sadness',
        'anger': 'angry', 'furious': 'angry',
        
        # Locations
        'beach': 'shore', 'coast': 'shore', 'seaside': 'shore',
        'mountain': 'mountains', 'hill': 'mountains',
        
        # Food
        'meal': 'food', 'dinner': 'food', 'lunch': 'food', 'breakfast': 'food',
        'dish': 'food', 'cuisine': 'food',
        
        # Generic
        'photograph': 'photo', 'picture': 'photo', 'image': 'photo'
    }
    
    # Function to normalize a term using the mapping
    def normalize_term(term):
        # Convert to lowercase for consistent matching
        term_lower = term.lower()
        # Direct matches
        if term_lower in term_mapping:
            return term_mapping[term_lower]
        # Partial matches (for compound terms)
        for key, value in term_mapping.items():
            if key in term_lower:
                return value
        # Keep original if no mapping
        return term
    
    # Process labels
    if 'labels' in results and results['labels']:
        normalized_labels = []
        seen_terms = set()
        
        for label in results['labels']:
            norm_term = normalize_term(label['description'])
            # Only add if we haven't seen this normalized term yet
            if norm_term not in seen_terms:
                seen_terms.add(norm_term)
                # Use the normalized term but keep original score
                normalized_labels.append({
                    'description': norm_term.title(),  # Capitalize first letter
                    'score': label['score']
                })
        
        # Replace with the deduplicated list
        results['labels'] = normalized_labels
    
    # Process objects
    if 'objects' in results and results['objects']:
        normalized_objects = []
        seen_terms = set()
        
        for obj in results['objects']:
            norm_term = normalize_term(obj['name'])
            # Only add if we haven't seen this normalized term yet
            if norm_term not in seen_terms:
                seen_terms.add(norm_term)
                # Use the normalized term but keep original score
                normalized_objects.append({
                    'name': norm_term.title(),  # Capitalize first letter
                    'score': obj['score']
                })
        
        # Replace with the deduplicated list
        results['objects'] = normalized_objects
    
    return results

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
