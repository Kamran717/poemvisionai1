import os
import logging
import functools
import secrets
from datetime import datetime, timedelta
import jwt
import time
from flask import Flask, render_template, request, jsonify, session, make_response, redirect, url_for, flash, current_app, g, Response
from flask_mail import Mail, Message
import base64
import uuid
import json
import string
import random
import re
import stripe
from typing import Union, Tuple
from stripe.error import StripeError
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from werkzeug.security import generate_password_hash, check_password_hash
from utils.image_analyzer import analyze_image
from utils.poem_generator import generate_poem
from utils.image_manipulator import create_framed_image
from utils.sendgrid_mail import send_email
from models import db, Creation, User, Membership, Transaction, ContactMessage, AdminUser, AdminRole, AdminLog
from models import SiteVisitor, VisitorLog, VisitorStats
from utils.membership import (create_default_plans, get_user_plan,
                              check_poem_type_access, check_frame_access,
                              process_payment, get_user_creations,
                              get_available_poem_types, get_available_frames,
                              check_poem_length_access,
                              get_available_poem_lengths)
from utils.visitor_tracking import track_visitor, update_visitor_stats

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
                    _view_cache[cache_key] = (datetime.now() +
                                              timedelta(seconds=timeout),
                                              response)
            else:
                # Regular response
                _view_cache[cache_key] = (datetime.now() +
                                          timedelta(seconds=timeout), response)

            return response

        return wrapper

    return decorator


# Initialize Flask app
app = Flask(__name__)
app.secret_key = os.environ.get("SESSION_SECRET", "dev-secret-key")
stripe.api_key = os.environ.get("STRIPE_SECRET_KEY")
stripe.api_version = "2023-08-16"
STRIPE_PUBLISHABLE_KEY = os.environ.get("STRIPE_PUBLISHABLE_KEY")

# Register admin blueprint
from admin import admin_bp
app.register_blueprint(admin_bp)

# Add global current_admin for templates
app.jinja_env.globals['current_admin'] = None

# Set up email configuration (SendGrid)
app.config['MAIL_DEFAULT_SENDER'] = 'Poem Vision <info@poemvisionai.com >'

# Set up database with connection pooling and retry settings
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
    "pool_pre_ping": True,
    "pool_recycle": 280,
    "pool_timeout": 30,
    "max_overflow": 15,
    "pool_size": 10,
    "connect_args": {
        "connect_timeout": 10
    }
}
db.init_app(app)

# Create all database tables if they don't exist
try:
    with app.app_context():
        db.create_all()
        logger.info("Database tables created successfully")
except Exception as e:
    logger.error(f"Error creating database tables: {str(e)}", exc_info=True)

# Set up visitor tracking
@app.before_request
def before_request():
    # Skip static files, admin routes, and API routes
    if not request.path.startswith('/static') and not request.path.startswith('/admin') and not request.path.startswith('/api'):
        # Store request start time for calculating duration
        g.start_time = time.time()
        
        # Track the visitor
        user_id = session.get('user_id')
        try:
            visitor_id, is_new_visitor = track_visitor(user_id)
            g.visitor_id = visitor_id
            g.is_new_visitor = is_new_visitor
        except Exception as e:
            logger.error(f"Error tracking visitor: {str(e)}", exc_info=True)
            # Continue processing the request even if tracking fails
            g.visitor_id = None
            g.is_new_visitor = False

@app.after_request
def after_request(response):
    # Skip static files, admin routes, and API routes
    if hasattr(g, 'start_time') and hasattr(g, 'visitor_id') and g.visitor_id:
        try:
            # Calculate time spent on the page
            time_spent = int((time.time() - g.start_time) * 1000)  # in milliseconds
            
            # Update the visitor log with time spent
            visitor_log = VisitorLog.query.filter_by(
                visitor_id=g.visitor_id,
                page_visited=request.path
            ).order_by(VisitorLog.timestamp.desc()).first()
            
            if visitor_log:
                visitor_log.time_spent_seconds = time_spent / 1000  # convert to seconds
                db.session.commit()
        except Exception as e:
            logger.error(f"Error updating visitor time spent: {str(e)}", exc_info=True)
    
    return response

# Schedule daily visitor stats update
def update_daily_visitor_stats():
    """Update visitor statistics daily at midnight"""
    with app.app_context():
        try:
            logger.info("Updating daily visitor statistics")
            stats = update_visitor_stats()
            logger.info(f"Updated visitor stats: {stats}")
        except Exception as e:
            logger.error(f"Error updating visitor stats: {str(e)}", exc_info=True)

# For development purposes, initialize with some data if tables are empty
@app.cli.command("init-visitor-data")
def init_visitor_data():
    """Initialize visitor tracking data for development purposes"""
    from utils.visitor_tracking import populate_demo_data
    with app.app_context():
        try:
            # Check if we have any visitor stats
            if VisitorStats.query.count() == 0:
                logger.info("Initializing visitor tracking data")
                populate_demo_data()
                logger.info("Visitor tracking data initialized")
            else:
                logger.info("Visitor tracking data already exists, skipping initialization")
        except Exception as e:
            logger.error(f"Error initializing visitor data: {str(e)}", exc_info=True)


# Routes
@app.route('/')
def index():
    """Render the main page of the application."""
    # Check if user is logged in
    user_id = session.get('user_id')
    user = User.query.get(user_id) if user_id else None

    return render_template('index.html', user=user)


@app.route('/analyze-image', methods=['POST'])
def analyze_image_route() -> Union[Response, Tuple[Response, int]]:
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
                return jsonify(
                    {'error': 'No image uploaded. Please try again.'}), 400

            image_file = request.files['image']

            if image_file.filename == '':
                logger.error("Empty filename in uploaded file")
                return jsonify(
                    {'error': 'No image selected. Please try again.'}), 400

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
                    return jsonify(
                        {'error':
                         'No image data provided. Please try again.'}), 400

                # Get the base64 image string, removing data URL prefix if present
                base64_image = json_data['image']
                if ',' in base64_image:
                    base64_image = base64_image.split(',')[1]

                # Check size of base64 data
                estimated_size = len(base64_image) * 3 / 4  # Rough estimation
                file_size = estimated_size
                logger.info(
                    f"Estimated upload size from base64: {estimated_size/1024/1024:.2f}MB"
                )

                if estimated_size > 5 * 1024 * 1024:  # 5MB limit
                    return jsonify({
                        'error':
                        'Image size exceeds the 5MB limit. Please choose a smaller image.'
                    }), 400

                # Store the base64 data
                image_data = base64_image

                # Create a file-like object for analysis
                import io
                image_bytes = base64.b64decode(base64_image)
                image_file = io.BytesIO(image_bytes)
                # Add a placeholder filename attribute for logging
                image_file.filename = "mobile_upload.jpg"

            except Exception as e:
                logger.error(f"Error processing JSON image data: {str(e)}",
                             exc_info=True)
                return jsonify(
                    {'error': 'Invalid image data. Please try again.'}), 400
        else:
            logger.error(f"Unsupported content type: {request.content_type}")
            return jsonify(
                {'error': 'Unsupported upload method. Please try again.'}), 400

        # Check file size - limit to 5MB (final check)
        if file_size > 5 * 1024 * 1024:  # 5MB limit
            return jsonify({
                'error':
                'Image size exceeds the 5MB limit. Please choose a smaller image.'
            }), 400

        # Generate a shorter unique ID for this analysis
        analysis_id = str(uuid.uuid4()).split('-')[0]

        # Reset file pointer and read image data
        image_file.seek(0)

        # Some mobile browsers may send strange content types
        # Store original data regardless
        image_data = base64.b64encode(image_file.read()).decode('utf-8')

        # Analyze the image using Google Cloud Vision AI
        image_file.seek(0)
        logger.info(
            f"Analyzing image: {image_file.filename} ({file_size/1024:.1f} KB)"
        )

        try:
            # Get raw analysis results from Google Vision API
            analysis_results = analyze_image(image_file)

            # Check if we got valid analysis results
            if not analysis_results or '_error' in analysis_results:
                error_msg = analysis_results.get(
                    '_error', 'Unknown error during image analysis')
                logger.error(f"Image analysis failed: {error_msg}")
                return jsonify(
                    {'error': f'Error analyzing image: {error_msg}'}), 500

            # Clean up and deduplicate the analysis results to avoid redundant terms
            analysis_results = deduplicate_elements(analysis_results)

        except Exception as analysis_error:
            logger.error(
                f"Exception during image analysis: {str(analysis_error)}",
                exc_info=True)
            return jsonify({
                'error':
                'Error analyzing image. Please try again with a different image.'
            }), 500

        # Create a temporary creation in the database with retry mechanism
        max_retries = 3
        retry_count = 0

        while retry_count < max_retries:
            try:
                # Create a new session for each attempt to avoid stale connections
                db.session.close()

                # Check if user is logged in to assign creation to their account
                user_id = session.get('user_id')

                temp_creation = Creation()
                temp_creation.image_data = image_data
                temp_creation.analysis_results = analysis_results
                temp_creation.share_code = f"temp{analysis_id}"
                temp_creation.user_id = user_id
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
                logger.warning(
                    f"Database error (attempt {retry_count}/{max_retries}): {str(db_error)}"
                )

                # Roll back the failed transaction
                db.session.rollback()

                if retry_count >= max_retries:
                    logger.error(
                        f"Database error after {max_retries} attempts: {str(db_error)}",
                        exc_info=True)
                    return jsonify({
                        'error':
                        'Error saving analysis results. Please try again with a smaller image.'
                    }), 500

                # Wait briefly before retrying (exponential backoff)
                import time
                time.sleep(0.5 * retry_count)

    except Exception as e:
        logger.error(f"Unexpected error analyzing image: {str(e)}",
                     exc_info=True)
        return jsonify(
            {'error': 'An unexpected error occurred. Please try again.'}), 500


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
        poem_type = data.get('poemType', 'general verse')
        poem_length = data.get('poemLength', 'short')
        emphasis = data.get('emphasis', [])
        is_regeneration = data.get('isRegeneration', False)

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
            poem = generate_poem(analysis_results,
                                 poem_type,
                                 poem_length,
                                 emphasis,
                                 custom_terms=custom_terms,
                                 custom_category=custom_category,
                                 is_regeneration=is_regeneration)
        else:
            # Generate poem without custom prompt
            poem = generate_poem(analysis_results,
                                 poem_type,
                                 poem_length,
                                 emphasis,
                                 is_regeneration=is_regeneration)

        # Calculate time saved based on poem length
        time_saved_minutes = 0
        if poem_length == 'short':
            time_saved_minutes = 25  # Average 25 minutes saved for short poems (4-6 lines)
        elif poem_length == 'medium':
            time_saved_minutes = 90  # Average 90 minutes (1.5 hours) saved for medium poems (10-12 lines)
        elif poem_length == 'long':
            time_saved_minutes = 180  # Average 180 minutes (3 hours) saved for long poems (20+ lines)
        else:
            time_saved_minutes = 45  # Default to 45 minutes if length is unknown

        # Update the temporary creation with the poem and time saved data
        temp_creation.poem_text = poem
        temp_creation.poem_type = poem_type
        temp_creation.emphasis = emphasis
        temp_creation.poem_length = poem_length
        temp_creation.time_saved_minutes = time_saved_minutes

        db.session.commit()

        return jsonify({'success': True, 'poem': poem})

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
            temp_creation.poem_text)

        # Convert the final image to base64 for sending to the client
        final_image_base64 = base64.b64encode(final_image).decode('utf-8')

        # Generate a unique share code
        share_code = ''.join(
            random.choices(string.ascii_uppercase + string.digits, k=10))

        # Create the final creation by updating the temporary one
        temp_creation.frame_style = frame_style
        temp_creation.final_image_data = final_image_base64
        temp_creation.share_code = share_code
        db.session.commit()

        return jsonify({
            'success': True,
            'finalImage': final_image_base64,
            'shareCode': share_code,
            'creationId': temp_creation.id
        })

    except Exception as e:
        logger.error(f"Error creating final image: {str(e)}", exc_info=True)
        return jsonify({'error':
                        f'Failed to create final image: {str(e)}'}), 500


@app.route('/shared/<share_code>')
@cache_view(timeout=3600)
def view_shared_creation(share_code):
    """View a shared creation by its share code."""
    try:
        # Look up the creation in the database and join with user table
        creation = Creation.query.filter_by(share_code=share_code).first()

        if not creation:
            return render_template(
                'error.html',
                message="Creation not found or no longer available"), 404

        # Get the creator's username if available
        creator_username = None
        if creation.user_id:
            creator = User.query.get(creation.user_id)
            if creator:
                creator_username = creator.username

        # Render the shared creation template
        return render_template('shared.html',
                               creation=creation,
                               creator_username=creator_username)

    except Exception as e:
        logger.error(f"Error viewing shared creation: {str(e)}", exc_info=True)
        return render_template(
            'error.html',
            message="An error occurred while loading this creation"), 500


@app.route('/gallery')
@cache_view(timeout=300)  # Cache gallery for 5 minutes
def gallery():
    """View a gallery of recent creations."""
    try:
        # Get the most recent 20 creations
        creations = Creation.query.order_by(
            Creation.created_at.desc()).limit(20).all()

        return render_template('gallery.html', creations=creations)

    except Exception as e:
        logger.error(f"Error loading gallery: {str(e)}", exc_info=True)
        return render_template(
            'error.html',
            message="An error occurred while loading the gallery"), 500


# Authentication and Membership Routes


@app.route('/login', methods=['GET', 'POST'])
def login():
    """Log in a user"""
    if request.method == 'POST':
        email = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '')

        # Validate inputs
        if not email or not password:
            return jsonify(
                {'error': 'Please provide both email and password.'}), 400

        # Find the user
        user = User.query.filter_by(email=email).first()

        # Check if user exists and password is correct
        if user and user.check_password(password):
            # Temporarily disabled email verification requirement for testing
            # if not user.is_email_verified:
            #    return jsonify({
            #        'error': 'Please verify your email before logging in.',
            #        'verification_required': True
            #    }), 401

            session['user_id'] = user.id
            return jsonify({'success': True, 'redirect': url_for('index')})
        else:
            return jsonify({'error': 'Invalid email or password.'}), 401

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
            return jsonify({'error':
                            'Please fill in all required fields.'}), 400

        if password != confirm_password:
            return jsonify({'error': 'Passwords do not match.'}), 400

        # Check if email or username already exists
        if User.query.filter_by(email=email).first():
            return jsonify({
                'error':
                'Email already registered. Please use a different email or log in.'
            }), 400

        if User.query.filter_by(username=username).first():
            return jsonify({
                'error':
                'Username already taken. Please choose a different username.'
            }), 400

        # Create new user
        new_user = User()
        new_user.username = username
        new_user.email = email
        new_user.set_password(password)

        # Set to free tier by default
        new_user.is_premium = False

        try:
            db.session.add(new_user)
            
            # Set email as verified by default for testing purposes
            # Remove this in production when SMTP is properly configured
            new_user.is_email_verified = True
            
            db.session.commit()

            # Try to send verification email, but don't fail registration if it doesn't work
            try:
                send_verification_email(new_user)
                return jsonify({
                    'success': True,
                    'message': 'Please check your email to verify your account',
                    'redirect': url_for('verification_pending')
                })
            except Exception as mail_error:
                logger.warning(f"Email verification couldn't be sent: {str(mail_error)}")
                # Continue registration despite email verification failure
                session['user_id'] = new_user.id
                return jsonify({
                    'success': True,
                    'message': 'Account created successfully!',
                    'redirect': url_for('index')
                })

        except Exception as e:
            db.session.rollback()
            logger.error(f"Error creating user: {str(e)}", exc_info=True)
            return jsonify({
                'error':
                'An error occurred while creating your account. Please try again.'
            }), 500

    return render_template('signup.html')


@app.route('/verify-email/<token>')
def verify_email(token):
    """Verify user's email using the token"""
    user = User.query.filter_by(email_verification_token=token).first()

    if not user or not user.is_token_valid(token):
        flash(
            'Invalid or expired verification link. Please request a new one.',
            'danger')
        return redirect(url_for('login'))

    user.verify_email()
    db.session.commit()

    # Log the user in
    session['user_id'] = user.id
    flash('Your email has been verified. Welcome!', 'success')
    return redirect(url_for('index'))


@app.route('/verification-pending')
def verification_pending():
    """Show a page informing the user to check their email"""
    return render_template('verification_pending.html')


@app.route('/resend-verification', methods=['GET', 'POST'])
def resend_verification():
    """Resend verification email"""
    if request.method == 'POST':
        email = request.form.get('email', '').strip().lower()
        user = User.query.filter_by(email=email).first()

        if user and not user.is_email_verified:
            send_verification_email(user)
            flash(
                'Verification email has been resent. Please check your inbox.',
                'success')
        else:
            flash('Email not found or already verified.', 'warning')

        return redirect(url_for('login'))

    return render_template('resend_verification.html')


def send_verification_email(user):
    """Send email verification link to the user using SendGrid"""
    token = user.generate_verification_token()
    db.session.commit()
    verification_url = url_for('verify_email', token=token, _external=True)

    # Create the body of the message (plain-text and HTML versions)
    text = f"""Hello {user.username},

Thank you for signing up! Please verify your email by clicking on the link below:

{verification_url}

This link will expire in 24 hours.

If you did not register for an account, please ignore this email.

Best regards,
Poem Vision Team
"""

    html = f"""\
    <html>
    <body>
        <h2>Hello {user.username},</h2>
        <p>Thank you for signing up! Please verify your email by clicking the button below:</p>
        <p><a href="{verification_url}" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Verify Email</a></p>
        <p>Or copy this link into your browser:<br>{verification_url}</p>
        <p>This link will expire in 24 hours.</p>
        <p>If you did not register for an account, please ignore this email.</p>
        <br>
        <p>Best regards,<br>Poem Vision Team</p>
    </body>
    </html>
    """

    try:
        # Send the email using SendGrid
        result = send_email(
            to_email=user.email,
            subject="Verify Your Email",
            text_content=text,
            html_content=html,
            from_email=app.config['MAIL_DEFAULT_SENDER']
        )
        
        if result:
            logger.info(f"Verification email sent to {user.email} via SendGrid")
        else:
            logger.error(f"Failed to send verification email to {user.email} via SendGrid")
            raise Exception("Failed to send verification email via SendGrid")
            
    except Exception as e:
        logger.error(f"Failed to send verification email: {str(e)}")
        raise


def check_user_verified():
    # Temporarily disable email verification checks for testing
    return None
    
    # The following code is disabled for testing purposes and will be re-enabled when email is configured
    '''
    # Routes accessible to anyone
    public_routes = [
        'login', 'signup', 'verify_email', 'verification_pending',
        'resend_verification', 'static', 'index', 'gallery',
        'view_shared_creation', 'contact_form'
    ]

    # Routes accessible to authenticated users regardless of verification
    auth_only_routes = [
        'index', 'view_shared_creation', 'analyze_image_route',
        'generate_poem_route', 'create_final_image_route', 'contact_form'
    ]

    if request.endpoint not in public_routes and 'user_id' in session:
        user = User.query.get(session['user_id'])
        if user and not user.is_email_verified and request.endpoint not in auth_only_routes:
            # For API requests
            if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return jsonify({'error': 'Email verification required'}), 401
            # For page requests
            flash('Please verify your email to access this feature.',
                  'warning')
            return redirect(url_for('verification_pending'))
    '''


@app.route('/logout')
def logout():
    """Log out a user"""
    # Remove user ID from session
    session.pop('user_id', None)
    return redirect(url_for('index'))


@app.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    """Handle forgot password request using SMTP"""
    if request.method == 'GET':
        return render_template('forgot_password.html')
        
    try:
        # Handle both JSON and form data
        if request.is_json:
            data = request.json
            email = data.get('email', '').strip().lower()
        else:
            email = request.form.get('email', '').strip().lower()

        if not email:
            return jsonify({'error': 'Email is required'}), 400

        user = User.query.filter_by(email=email).first()
        user = User.query.filter_by(email=email).first()
        print("User object:", user)
        if user:
            print("Username:", user.username)
            logger.info(f"Username: {user.username}")

        if not user:
            # For security, don't reveal if email doesn't exist
            return jsonify({
                'success':
                True,
                'message':
                'If an account exists with this email, a password reset link has been sent.'
            })

        # Generate password reset token (expires in 1 hour)
        token = user.generate_password_reset_token()
        reset_url = url_for('reset_password', token=token, _external=True)

        # Create email content
        text = f"""Password Reset Request

You requested to reset your password. Click the link below to proceed:

{reset_url}

This link will expire in 1 hour.

If you didn't request this, please ignore this email.

Best regards,
Poem Vision Team
"""

        html = f"""\
        <html>
        <body>
            <h2>Password Reset</h2>
            <p>Hi {user.username}</p>
            <p>We received a request to reset your password. If this was you, you can securely update your password by clicking the button below:</p>
            <p><a href="{reset_url}" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Reset Password</a></p>
            <p>Or copy this link into your browser:<br>{reset_url}</p>
            <p>This link will expire in 1 hour.</p>
            <p>If you didn’t request a password reset, no action is needed. Your account remains secure.</p>
            <br>
            <p>Warm regards,<br>The Poem Vision AI Team <br>www.poemvision.ai</p>
        </body>
        </html>
        """
        print("HTML to be sent:\n", html)
        try:
            # Send the email using SendGrid
            result = send_email(
                to_email=user.email,
                subject="Password Reset Request",
                text_content=text,
                html_content=html,
                from_email=app.config['MAIL_DEFAULT_SENDER']
            )
            
            if result:
                logger.info(f"Password reset email sent to {user.email} via SendGrid")
                return jsonify({
                    'success': True,
                    'message': 'If an account exists with this email, a password reset link has been sent.'
                })
            else:
                logger.error(f"Failed to send password reset email to {user.email} via SendGrid")
                
                # Check if we're in development mode where the app should still work
                if os.environ.get('FLASK_ENV') == 'development':
                    logger.warning("Running in development mode, simulating email delivery success")
                    return jsonify({
                        'success': True,
                        'message': 'If an account exists with this email, a password reset link has been sent.',
                        'dev_note': f'Email delivery simulated in development mode. Reset URL: {reset_url}'
                    })
                else:
                    # In production, return a more helpful error message
                    return jsonify({
                        'error': 'Failed to send password reset email. Email system is currently unavailable.',
                        'details': 'Please try again later or contact support.'
                    }), 500

        except Exception as e:
            error_msg = str(e)
            logger.error(f"Failed to send password reset email: {error_msg}")
            
            # Check if this is a SendGrid verification error
            if "verified Sender Identity" in error_msg:
                logger.error("SendGrid sender verification issue detected")
                return jsonify({
                    'error': 'Email service configuration issue detected.',
                    'details': 'The system administrator needs to verify the sender email in SendGrid.'
                }), 500
            else:
                return jsonify({
                    'error': 'Failed to send password reset email',
                    'details': 'Please try again later or contact support.'
                }), 500

    except Exception as e:
        logger.error(f"Error in forgot password: {str(e)}", exc_info=True)
        return jsonify({'error':
                        'Failed to process password reset request'}), 500


@app.route('/reset-password/<token>', methods=['GET', 'POST'])
def reset_password(token):
    """Handle password reset"""
    if request.method == 'GET':
        # Verify token and show reset form
        user = User.verify_password_reset_token(token)
        if not user:
            flash('Invalid or expired password reset link', 'danger')
            return redirect(url_for('login'))
        return render_template('reset_password.html', token=token)

    else:  # POST
        try:
            data = request.form
            token = data.get('token')
            password = data.get('password')
            confirm_password = data.get('confirm_password')

            if not password or not confirm_password:
                flash('Please fill in all fields', 'danger')
                return redirect(url_for('reset_password', token=token))

            if password != confirm_password:
                flash('Passwords do not match', 'danger')
                return redirect(url_for('reset_password', token=token))

            user = User.verify_password_reset_token(token)
            if not user:
                flash('Invalid or expired password reset link', 'danger')
                return redirect(url_for('login'))

            # Update password
            user.set_password(password)
            db.session.commit()

            flash('Your password has been updated. Please log in.', 'success')
            return redirect(url_for('login'))

        except Exception as e:
            db.session.rollback()
            logger.error(f"Error resetting password: {str(e)}", exc_info=True)
            flash('An error occurred while resetting your password', 'danger')
            return redirect(url_for('reset_password', token=token))


@app.route('/profile')
def profile():
    """View user profile and creations"""
    # Check if user is logged in
    if 'user_id' not in session:
        return redirect(url_for('login'))

    user_id = session['user_id']
    user = User.query.get(user_id)

    if not user:
        session.pop('user_id', None)
        return redirect(url_for('login'))

    # Get user's creations
    user_creations = get_user_creations(user_id, limit=20)

    # Get user's membership plan
    plan = get_user_plan(user_id)

    # Calculate time saved statistics
    time_saved_stats = user.get_time_saved_stats()

    return render_template('profile.html',
                           user=user,
                           creations=user_creations,
                           plan=plan,
                           time_saved_stats=time_saved_stats)


@app.route('/api/contact', methods=['POST'])
def contact_form():
    """Handle contact form submissions"""
    try:
        # Handle both JSON and form data
        if request.is_json:
            data = request.json
        else:
            data = {
                'name': request.form.get('name', ''),
                'email': request.form.get('email', ''),
                'subject': request.form.get('subject', ''),
                'message': request.form.get('message', '')
            }
        
        logger.debug(f"Received contact form data: {data}")

        # Validate required fields
        if not all(key in data and data[key].strip()
                   for key in ['name', 'email', 'subject', 'message']):
            return jsonify({'error': 'All fields are required'}), 400

        # Basic email validation
        if not re.match(r"[^@]+@[^@]+\.[^@]+", data['email']):
            return jsonify({'error': 'Invalid email address'}), 400

        # Create new contact message
        new_message = ContactMessage(name=data['name'],
                                     email=data['email'],
                                     subject=data['subject'],
                                     message=data['message'])

        db.session.add(new_message)
        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Thank you for your message!'
        })

    except Exception as e:
        db.session.rollback()
        logger.error(f"Error saving contact message: {str(e)}", exc_info=True)
        return jsonify(
            {'error': 'Failed to send message. Please try again later.'}), 500


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
    """Upgrade to premium membership with Stripe integration"""
    # Check if user is logged in
    if 'user_id' not in session:
        return redirect(url_for('login'))

    user_id = session['user_id']
    user = User.query.get(user_id)

    if not user:
        session.pop('user_id', None)
        return redirect(url_for('login'))

    # If user is already premium
    if user.is_premium:
        return redirect(url_for('profile'))

    # Get premium plan details
    premium_plan = Membership.query.filter_by(name='Premium').first()

    if request.method == 'POST':
        try:
            # Get the payment method ID from the request
            data = request.json
            payment_method_id = data.get('payment_method_id')

            if not payment_method_id:
                return jsonify({'error': 'Payment method not provided'}), 400

            # Get billing details from request
            billing_details = data.get('billing_details', {})
            billing_name = billing_details.get('name', user.username)
            billing_address = billing_details.get('address', {})
            
            # Create a Stripe customer if not exists
            if not user.stripe_customer_id:
                customer = stripe.Customer.create(
                    email=user.email,
                    name=billing_name,
                    payment_method=payment_method_id,
                    address=billing_address,
                    invoice_settings={
                        'default_payment_method': payment_method_id
                    })
                user.stripe_customer_id = customer.id
                db.session.commit()
            else:
                # Attach the payment method to existing customer
                stripe.PaymentMethod.attach(
                    payment_method_id,
                    customer=user.stripe_customer_id,
                )
                # Update customer details with new billing information
                stripe.Customer.modify(
                    user.stripe_customer_id,
                    name=billing_name,
                    address=billing_address,
                    invoice_settings={
                        'default_payment_method': payment_method_id
                    })

            # Create a subscription with expanded invoice and payment intent
            subscription = stripe.Subscription.create(
                customer=user.stripe_customer_id,
                items=[{
                    'price': premium_plan.stripe_price_id,
                }],
                expand=['latest_invoice.payment_intent'],
                metadata={
                    'user_id': user.id,
                    'plan_id': premium_plan.id
                })

            user.subscription_id = subscription.id

            # Check if we actually got the expanded objects
            if hasattr(subscription, 'latest_invoice') and isinstance(
                    subscription.latest_invoice, stripe.Invoice):
                invoice = subscription.latest_invoice

                if hasattr(invoice,
                           'payment_intent') and invoice.payment_intent:
                    # Access the payment intent status
                    if invoice.payment_intent.status == 'succeeded':
                        # Update user to premium
                        user.is_premium = True

                        # Set membership dates
                        user.membership_start = datetime.utcnow()
                        # Get the current period end from the subscription
                        current_period_end = datetime.fromtimestamp(
                            subscription.current_period_end)
                        user.membership_end = current_period_end

                        # Record the transaction
                        transaction = Transaction()
                        transaction.user_id = user.id
                        transaction.membership_id = premium_plan.id
                        transaction.amount = premium_plan.price
                        transaction.currency = 'USD'
                        transaction.transaction_id = invoice.payment_intent.id
                        transaction.status = 'completed'
                        db.session.add(transaction)
                        db.session.commit()

                        return jsonify({
                            'success':
                            True,
                            'redirect':
                            url_for('profile'),
                            'message':
                            'Subscription created successfully!'
                        })
                    else:
                        # Handle payment that requires action
                        return jsonify({
                            'error':
                            'Payment requires additional action',
                            'requires_action':
                            True,
                            'payment_intent_client_secret':
                            invoice.payment_intent.client_secret
                        }), 400
                else:
                    # Handle case where payment intent is not available
                    logger.error(
                        f"Payment intent not available in the invoice: {invoice.id}"
                    )
                    return jsonify({
                        'error':
                        'Payment processing issue. Please try again.'
                    }), 500
            else:
                # Handle case where latest_invoice is not expanded
                logger.error(
                    "Latest invoice not expanded in subscription response")

                # Try to retrieve the invoice separately
                try:
                    invoice = stripe.Invoice.retrieve(
                        subscription.latest_invoice, expand=['payment_intent'])

                    if invoice.payment_intent.status == 'succeeded':
                        # Update user to premium
                        user.is_premium = True

                        # Set membership dates
                        user.membership_start = datetime.utcnow()
                        # Get the current period end from the subscription
                        current_period_end = datetime.fromtimestamp(
                            subscription.current_period_end)
                        user.membership_end = current_period_end

                        # Record the transaction
                        transaction = Transaction()
                        transaction.user_id = user.id
                        transaction.membership_id = premium_plan.id
                        transaction.amount = premium_plan.price
                        transaction.currency = 'USD'
                        transaction.transaction_id = invoice.payment_intent.id
                        transaction.status = 'completed'
                        db.session.add(transaction)
                        db.session.commit()

                        return jsonify({
                            'success':
                            True,
                            'redirect':
                            url_for('profile'),
                            'message':
                            'Subscription created successfully!'
                        })
                    else:
                        return jsonify({
                            'error':
                            'Payment requires additional action',
                            'requires_action':
                            True,
                            'payment_intent_client_secret':
                            invoice.payment_intent.client_secret
                        }), 400
                except Exception as e:
                    logger.error(f"Error retrieving invoice: {str(e)}")
                    return jsonify({
                        'error':
                        'Payment processing issue. Please try again.'
                    }), 500

        except StripeError as e:
            logger.error(f"Stripe error during payment: {str(e)}",
                         exc_info=True)
            return jsonify({
                'error':
                str(e.user_message) if hasattr(e, 'user_message')
                and e.user_message else 'Payment processing failed'
            }), 500
        except Exception as e:
            logger.error(f"Error processing payment: {str(e)}", exc_info=True)
            db.session.rollback()
            return jsonify(
                {'error': 'An error occurred during payment processing'}), 500

    # For GET requests, render the upgrade page with Stripe publishable key
    return render_template('upgrade.html',
                           plan=premium_plan,
                           user=user,
                           stripe_publishable_key=STRIPE_PUBLISHABLE_KEY)


@app.route('/stripe-webhook', methods=['POST'])
def stripe_webhook():
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')
    webhook_secret = os.environ.get('STRIPE_WEBHOOK_SECRET')

    try:
        event = stripe.Webhook.construct_event(payload, sig_header,
                                               webhook_secret)
    except ValueError as e:
        # Invalid payload
        logger.error(f"Invalid Stripe webhook payload: {str(e)}")
        return jsonify({'error': 'Invalid payload'}), 400
    except stripe.error.SignatureVerificationError as e:
        # Invalid signature
        logger.error(f"Invalid Stripe webhook signature: {str(e)}")
        return jsonify({'error': 'Invalid signature'}), 400

    # Handle the event
    if event['type'] == 'invoice.payment_succeeded':
        invoice = event['data']['object']
        # Handle successful payment (e.g., extend membership)
        handle_payment_succeeded(invoice)
    elif event['type'] == 'customer.subscription.deleted':
        subscription = event['data']['object']
        # Handle subscription cancellation
        handle_subscription_cancelled(subscription)
    # Add more event handlers as needed

    return jsonify({'success': True}), 200


def handle_payment_succeeded(invoice):
    try:
        subscription = stripe.Subscription.retrieve(invoice.subscription)
        user_id = subscription.metadata.get('user_id')

        if user_id:
            user = User.query.get(user_id)
            if user:
                user.is_premium = True

                # Add these lines
                user.membership_start = datetime.utcnow()
                # Set end date based on billing cycle, using subscription data
                current_period_end = datetime.fromtimestamp(
                    subscription.current_period_end)
                user.membership_end = current_period_end

                db.session.commit()
                logger.info(f"Updated user {user_id} membership after payment")
    except Exception as e:
        logger.error(f"Error handling payment succeeded webhook: {str(e)}")


@app.route('/cancel-subscription', methods=['POST'])
def cancel_subscription():
    """Handle subscription cancellation request from frontend"""
    if 'user_id' not in session:
        return jsonify({'error': 'Not authenticated'}), 401

    user = User.query.get(session['user_id'])
    if not user or not user.is_premium or not user.subscription_id:
        return jsonify({'error': 'No active subscription'}), 400

    try:
        # Set subscription to cancel at period end
        stripe.Subscription.modify(user.subscription_id,
                                   cancel_at_period_end=True)

        # Update user state
        user.is_cancelled = True
        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Subscription will cancel at period end',
            'end_date': user.membership_end.strftime('%B %d, %Y')
        })

    except stripe.error.StripeError as e:
        logger.error(f"Stripe cancellation error: {str(e)}")
        return jsonify({
            'error':
            str(e.user_message)
            if hasattr(e, 'user_message') else 'Cancellation failed'
        }), 500
    except Exception as e:
        db.session.rollback()
        logger.error(f"Subscription cancellation error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


def handle_subscription_cancelled(subscription):
    """Handle subscription cancellation from Stripe webhook"""
    try:
        user_id = subscription.metadata.get('user_id')
        if not user_id:
            return

        user = User.query.get(user_id)
        if not user:
            return

        # Case 1: Scheduled cancellation reached end date
        if subscription.status == 'canceled':
            user.is_premium = False
            user.membership_end = datetime.utcnow()
            user.is_cancelled = False
            logger.info(f"Fully canceled subscription for user {user_id}")

        # Case 2: User requested future cancellation
        elif subscription.cancel_at_period_end:
            user.is_cancelled = True
            logger.info(
                f"Marked subscription for future cancellation for user {user_id}"
            )

        db.session.commit()

    except Exception as e:
        logger.error(f"Webhook cancellation handling error: {str(e)}")
        db.session.rollback()


@app.route('/api/available-poem-lengths')
def available_poem_lengths():
    user_id = session.get('user_id')
    user = User.query.get(user_id) if user_id else None
    lengths = get_available_poem_lengths(user_id)
    return jsonify({
        'poem_lengths': lengths,
        'is_premium': user.is_premium if user else False
    })


@app.route('/api/check-access', methods=['POST'])
def check_access():
    data = request.json
    feature_type = data.get('type')
    feature_id = data.get('id')
    user_id = session.get('user_id')

    if feature_type == 'poem_type':
        has_access = check_poem_type_access(user_id, feature_id)
    elif feature_type == 'frame':
        has_access = check_frame_access(user_id, feature_id)
    elif feature_type == 'poem_length':
        has_access = check_poem_length_access(user_id, feature_id)
    else:
        return jsonify({'error': 'Invalid feature type'}), 400

    return jsonify({
        'has_access':
        has_access,
        'is_premium':
        current_user.is_premium if current_user.is_authenticated else False
    })


@app.route('/api/available-poem-types')
def api_available_poem_types():
    """API endpoint to get available poem types for the current user"""
    try:
        # Get user ID from session
        user_id = session.get('user_id')

        # Get available poem types
        poem_types = get_available_poem_types(user_id)

        return jsonify({
            'poem_types':
            poem_types,
            'is_premium':
            bool(user_id and User.query.get(user_id)
                 and User.query.get(user_id).is_premium)
        })

    except Exception as e:
        logger.error(f"Error getting available poem types: {str(e)}",
                     exc_info=True)
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
            'frames':
            frames,
            'is_premium':
            bool(user_id and User.query.get(user_id)
                 and User.query.get(user_id).is_premium)
        })

    except Exception as e:
        logger.error(f"Error getting available frames: {str(e)}",
                     exc_info=True)
        return jsonify({'error': str(e)}), 500


@app.route('/delete_creation/<int:creation_id>', methods=['DELETE'])
def delete_creation(creation_id):
    user_id = session.get('user_id')
    creation = Creation.query.get_or_404(creation_id)
    if creation.user_id != user_id:
        abort(403)

    db.session.delete(creation)
    db.session.commit()
    return jsonify({'success': True})


# Helper function to deduplicate and simplify elements for emphasis
def deduplicate_elements(analysis_results):
    """
    Enhanced deduplication with better term normalization and merging.
    """
    if not analysis_results:
        return analysis_results

    results = analysis_results.copy()

    # Expanded term mapping with priority to more general terms
    term_mapping = {
        # Transportation
        'mode of transport': 'transport',
        'automotive tire': 'tire',
        'automotive wheel system': 'wheel',
        'automotive mirror': 'mirror',
        'public transport': 'transport',
        'rolling': 'wheel',

        # Clothing
        'pants': 'clothing',
        'top': 'clothing',
        'outerwear': 'clothing',
        'shoe': 'footwear',
        'footwear': 'clothing',

        # People
        'head': 'person',
        'child': 'person',
        'toddler': 'person',

        # Emotions/Activities
        'happiness': 'emotion',
        'smile': 'emotion',
        'fun': 'activity',
        'leisure': 'activity',
        'recreation': 'activity',
        'vacation': 'activity',
        'holiday': 'activity',
        'travel': 'activity',

        # Locations
        'park': 'location',
        'fence': 'structure',

        # Seasonal
        'spring': 'season'
    }

    def normalize_term(term):
        term_lower = term.lower().strip()

        # First check exact matches
        if term_lower in term_mapping:
            return term_mapping[term_lower]

        # Then check if any mapped term is contained in this term
        for key in sorted(term_mapping.keys(), key=len, reverse=True):
            if key in term_lower:
                return term_mapping[key]

        # Finally check if this term is contained in any mapped term
        for key, value in term_mapping.items():
            if term_lower in key:
                return value

        return term_lower

    # Process labels
    if 'labels' in results:
        seen_labels = set()
        deduped_labels = []

        for label in sorted(results['labels'], key=lambda x: -x['score']):
            norm_desc = normalize_term(label['description'])
            if norm_desc not in seen_labels:
                seen_labels.add(norm_desc)
                deduped_labels.append({
                    'description': norm_desc.title(),
                    'score': label['score']
                })

        results['labels'] = deduped_labels

    # Process objects - with special handling for plurals
    if 'objects' in results:
        seen_objects = set()
        deduped_objects = []

        for obj in sorted(results['objects'], key=lambda x: -x['score']):
            norm_name = normalize_term(obj['name'])

            # Handle simple plurals (basic English)
            singular = norm_name.rstrip('s') if norm_name.endswith(
                's') else norm_name
            if singular in seen_objects:
                continue

            seen_objects.add(singular)
            deduped_objects.append({
                'name': singular.title(),
                'score': obj['score']
            })

        results['objects'] = deduped_objects

    return results


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
