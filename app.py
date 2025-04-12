import os
import logging
import functools
from datetime import datetime, timedelta
from flask import Flask, render_template, request, jsonify, session, make_response, redirect, url_for, flash
import base64
import uuid
import json
import string
import random
import re
from werkzeug.security import generate_password_hash, check_password_hash
from utils.image_analyzer import analyze_image
from utils.poem_generator import generate_poem
from utils.image_manipulator import create_framed_image
from models import db, Creation, User, Membership, Transaction
from utils.membership import (create_default_plans, get_user_plan, 
                             check_poem_type_access, check_frame_access, 
                             process_payment, get_user_creations,
                             get_available_poem_types, get_available_frames)

# Set up logging first so we can use it everywhere
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Simple in-memory cache for shared views
_view_cache = {}

def cache_view(timeout=3600):  # Default cache of 1 hour
    """Cache decorator for view functions"""
    def decorator(f):
        @functools.wraps(f)
        def wrapper(*args, **kwargs):
            # Create a cache key from the function name and arguments
            # For shared views, this would be the share_code
            cache_key = f"{f.__name__}:{str(kwargs)}"
            
            # Try to get from cache first
            cached_response = _view_cache.get(cache_key)
            if cached_response:
                expiry_time, response = cached_response
                if datetime.now() < expiry_time:
                    logger.debug(f"Cache hit for {cache_key}")
                    return response
                # Remove expired cache entries
                del _view_cache[cache_key]
            
            # Generate the response
            response = f(*args, **kwargs)
            
            # Cache the response if it's not an error
            if isinstance(response, tuple):
                # Response with status code
                if response[1] == 200:
                    _view_cache[cache_key] = (datetime.now() + timedelta(seconds=timeout), response)
            else:
                # Regular response
                _view_cache[cache_key] = (datetime.now() + timedelta(seconds=timeout), response)
            
            return response
        return wrapper
    return decorator

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
    # Check if user is logged in
    user_id = session.get('user_id')
    user = User.query.get(user_id) if user_id else None
    
    return render_template('index.html', user=user)

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
                
                # Check if user is logged in to assign creation to their account
                user_id = session.get('user_id')
                
                temp_creation = Creation(
                    image_data=image_data,
                    analysis_results=analysis_results,
                    share_code=f"temp{analysis_id}",  # Shorter share_code
                    user_id=user_id  # Will be None for non-logged in users
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
        
        # Get structured custom prompt info if provided
        custom_prompt = data.get('customPrompt', {})
        custom_category = custom_prompt.get('category', '')
        
        # Check if we're using structured prompt format
        if custom_category == 'structured':
            # Extract structured fields
            name = custom_prompt.get('name', '')
            place = custom_prompt.get('place', '')
            emotion = custom_prompt.get('emotion', '')
            action = custom_prompt.get('action', '')
            additional = custom_prompt.get('additional', '')
            
            # Combine structured fields into a formatted prompt
            structured_terms = []
            if name:
                structured_terms.append(f"Name: {name}")
            if place:
                structured_terms.append(f"Place: {place}")
            if emotion:
                structured_terms.append(f"Emotion: {emotion}")
            if action:
                structured_terms.append(f"Action: {action}")
            if additional:
                structured_terms.append(f"Additional details: {additional}")
                
            custom_terms = "; ".join(structured_terms)
            logger.debug(f"Structured prompt created: {custom_terms}")
        else:
            # Legacy format - single text field
            custom_terms = custom_prompt.get('terms', '')
            
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
@cache_view(timeout=3600)  # Cache shared views for 1 hour
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
@cache_view(timeout=300)  # Cache gallery for 5 minutes
def gallery():
    """View a gallery of recent creations."""
    try:
        # Get the most recent 20 creations
        creations = Creation.query.order_by(Creation.created_at.desc()).limit(20).all()
        
        return render_template('gallery.html', creations=creations)
    
    except Exception as e:
        logger.error(f"Error loading gallery: {str(e)}", exc_info=True)
        return render_template('error.html', message="An error occurred while loading the gallery"), 500

# Authentication and Membership Routes

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Log in a user"""
    if request.method == 'POST':
        email = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '')
        
        # Validate inputs
        if not email or not password:
            return jsonify({'error': 'Please provide both email and password.'}), 400
        
        # Find the user
        user = User.query.filter_by(email=email).first()
        
        # Check if user exists and password is correct
        if user and user.check_password(password):
            # Store user ID in session
            session['user_id'] = user.id
            return jsonify({'success': True, 'redirect': url_for('index')})
        else:
            return jsonify({'error': 'Login failed. Please check your email and password.'}), 401
    
    return render_template('login.html')

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    """Register a new user"""
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        email = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '')
        confirm_password = request.form.get('confirm_password', '')
        
        # Validate inputs
        if not username or not email or not password:
            return jsonify({'error': 'Please fill in all required fields.'}), 400
        
        if password != confirm_password:
            return jsonify({'error': 'Passwords do not match.'}), 400
        
        # Check if email or username already exists
        if User.query.filter_by(email=email).first():
            return jsonify({'error': 'Email already registered. Please use a different email or log in.'}), 400
        
        if User.query.filter_by(username=username).first():
            return jsonify({'error': 'Username already taken. Please choose a different username.'}), 400
        
        # Create new user
        new_user = User(username=username, email=email)
        new_user.set_password(password)
        
        # Set to free tier by default
        new_user.is_premium = False
        
        try:
            db.session.add(new_user)
            db.session.commit()
            
            # Log the user in
            session['user_id'] = new_user.id
            return jsonify({'success': True, 'redirect': url_for('index')})
            
        except Exception as e:
            db.session.rollback()
            logger.error(f"Error creating user: {str(e)}", exc_info=True)
            return jsonify({'error': 'An error occurred while creating your account. Please try again.'}), 500
    
    return render_template('signup.html')

@app.route('/logout')
def logout():
    """Log out a user"""
    # Remove user ID from session
    session.pop('user_id', None)
    return redirect(url_for('index'))

@app.route('/profile')
def profile():
    """View user profile and creations"""
    # Check if user is logged in
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    user_id = session['user_id']
    user = User.query.get(user_id)
    
    if not user:
        session.pop('user_id', None)  # Clear invalid session
        return redirect(url_for('login'))
    
    # Get user's creations
    user_creations = get_user_creations(user_id, limit=20)
    
    # Get user's membership plan
    plan = get_user_plan(user_id)
    
    return render_template('profile.html', user=user, creations=user_creations, plan=plan)

@app.route('/membership')
def membership_plans():
    """View membership plans and pricing"""
    # Check if user is logged in
    user_id = session.get('user_id')
    user = User.query.get(user_id) if user_id else None
    
    # Get available plans
    plans = Membership.query.all()
    
    return render_template('membership.html', plans=plans, user=user)

@app.route('/upgrade', methods=['GET', 'POST'])
def upgrade_membership():
    """Upgrade to premium membership"""
    # Check if user is logged in
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    user_id = session['user_id']
    user = User.query.get(user_id)
    
    if not user:
        session.pop('user_id', None)  # Clear invalid session
        return redirect(url_for('login'))
    
    # If user is already premium
    if user.is_premium:
        return redirect(url_for('profile'))
    
    if request.method == 'POST':
        # This would be integrated with Stripe or another payment provider
        # For now, we'll simulate a successful payment
        payment_method = 'credit_card'
        transaction_id = f'demo_transaction_{random.randint(1000, 9999)}'
        
        # Process the payment
        result = process_payment(user_id, payment_method, transaction_id)
        
        if result['success']:
            return jsonify({'success': True, 'redirect': url_for('profile')})
        else:
            return jsonify({'error': f'Payment processing failed: {result["message"]}'}), 500
    
    # Get premium plan details
    premium_plan = Membership.query.filter_by(name='Premium').first()
    
    return render_template('upgrade.html', plan=premium_plan, user=user)

@app.route('/api/check-access', methods=['POST'])
def check_access():
    """API endpoint to check if a user has access to premium features"""
    try:
        data = request.json
        feature_type = data.get('type')  # 'poem_type' or 'frame'
        feature_id = data.get('id')
        
        # Get user ID from session
        user_id = session.get('user_id')
        
        # Check access based on feature type
        if feature_type == 'poem_type':
            has_access = check_poem_type_access(user_id, feature_id)
        elif feature_type == 'frame':
            has_access = check_frame_access(user_id, feature_id)
        else:
            return jsonify({'error': 'Invalid feature type'}), 400
        
        return jsonify({
            'has_access': has_access,
            'is_premium': bool(user_id and User.query.get(user_id) and User.query.get(user_id).is_premium)
        })
    
    except Exception as e:
        logger.error(f"Error checking access: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 500

@app.route('/api/available-poem-types')
def api_available_poem_types():
    """API endpoint to get available poem types for the current user"""
    try:
        # Get user ID from session
        user_id = session.get('user_id')
        
        # Get available poem types
        poem_types = get_available_poem_types(user_id)
        
        return jsonify({
            'poem_types': poem_types,
            'is_premium': bool(user_id and User.query.get(user_id) and User.query.get(user_id).is_premium)
        })
    
    except Exception as e:
        logger.error(f"Error getting available poem types: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 500

@app.route('/api/available-frames')
def api_available_frames():
    """API endpoint to get available frames for the current user"""
    try:
        # Get user ID from session
        user_id = session.get('user_id')
        
        # Get available frames
        frames = get_available_frames(user_id)
        
        return jsonify({
            'frames': frames,
            'is_premium': bool(user_id and User.query.get(user_id) and User.query.get(user_id).is_premium)
        })
    
    except Exception as e:
        logger.error(f"Error getting available frames: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 500

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
