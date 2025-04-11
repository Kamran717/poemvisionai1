import os
import logging
from flask import Flask, render_template, request, jsonify, session
import base64
import uuid
import json
import string
import random
from utils.image_analyzer import analyze_image
from utils.poem_generator import generate_poem
from utils.image_manipulator import create_framed_image
from models import db, Creation

# Initialize Flask app
app = Flask(__name__)
app.secret_key = os.environ.get("SESSION_SECRET", "dev-secret-key")

# Set up database
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db.init_app(app)

# Create all database tables if they don't exist
with app.app_context():
    db.create_all()

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Routes
@app.route('/')
def index():
    """Render the main page of the application."""
    return render_template('index.html')

@app.route('/analyze-image', methods=['POST'])
def analyze_image_route():
    """Analyze the uploaded image using Google Cloud Vision AI."""
    try:
        # Get the uploaded image from the request
        if 'image' not in request.files:
            return jsonify({'error': 'No image uploaded'}), 400
        
        image_file = request.files['image']
        
        if image_file.filename == '':
            return jsonify({'error': 'No image selected'}), 400
            
        # Check file size - limit to 10MB
        image_file.seek(0, os.SEEK_END)
        file_size = image_file.tell()
        if file_size > 10 * 1024 * 1024:
            return jsonify({'error': 'Image too large. Please upload an image smaller than 10MB'}), 400
        
        # Generate a shorter unique ID for this analysis
        analysis_id = str(uuid.uuid4()).split('-')[0]  # Just use the first part of the UUID
        
        # Reset file pointer and read image data
        image_file.seek(0)
        image_data = base64.b64encode(image_file.read()).decode('utf-8')
        
        # Analyze the image using Google Cloud Vision AI
        image_file.seek(0)  # Reset the file pointer again
        logger.info(f"Analyzing image: {image_file.filename} ({file_size/1024:.1f} KB)")
        
        try:
            analysis_results = analyze_image(image_file)
            
            # Check if we got valid analysis results
            if not analysis_results or '_error' in analysis_results:
                error_msg = analysis_results.get('_error', 'Unknown error during image analysis')
                logger.error(f"Image analysis failed: {error_msg}")
                return jsonify({'error': f'Error analyzing image: {error_msg}'}), 500
                
        except Exception as analysis_error:
            logger.error(f"Exception during image analysis: {str(analysis_error)}", exc_info=True)
            return jsonify({'error': 'Error analyzing image. Please try again with a different image.'}), 500
        
        # Create a temporary creation in the database
        try:
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
            logger.error(f"Database error: {str(db_error)}", exc_info=True)
            return jsonify({'error': 'Error saving analysis results. Please try again.'}), 500
    
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
        
        # Generate the poem using the LLM
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
