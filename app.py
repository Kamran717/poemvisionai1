import os
import logging
from flask import Flask, render_template, request, jsonify, session
import base64
import uuid
import json
from utils.image_analyzer import analyze_image
from utils.poem_generator import generate_poem
from utils.image_manipulator import create_framed_image

# Initialize Flask app
app = Flask(__name__)
app.secret_key = os.environ.get("SESSION_SECRET", "dev-secret-key")

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
        
        # Generate a unique ID for this analysis
        analysis_id = str(uuid.uuid4())
        
        # Save the uploaded image data in the session temporarily
        image_data = base64.b64encode(image_file.read()).decode('utf-8')
        session[f'image_{analysis_id}'] = image_data
        
        # Analyze the image using Google Cloud Vision AI
        analysis_results = analyze_image(image_file)
        
        # Store the analysis results in the session
        session[f'analysis_{analysis_id}'] = json.dumps(analysis_results)
        
        return jsonify({
            'success': True,
            'analysisId': analysis_id,
            'results': analysis_results
        })
    
    except Exception as e:
        logger.error(f"Error analyzing image: {str(e)}", exc_info=True)
        return jsonify({'error': f'Failed to analyze image: {str(e)}'}), 500

@app.route('/generate-poem', methods=['POST'])
def generate_poem_route():
    """Generate a poem based on image analysis and user preferences."""
    try:
        data = request.json
        analysis_id = data.get('analysisId')
        
        if not analysis_id or f'analysis_{analysis_id}' not in session:
            return jsonify({'error': 'Invalid or expired analysis ID'}), 400
        
        # Get the analysis results from the session
        analysis_results = json.loads(session[f'analysis_{analysis_id}'])
        
        # Get user preferences from the request
        poem_type = data.get('poemType', 'free verse')
        emphasis = data.get('emphasis', [])
        
        # Generate the poem using the LLM
        poem = generate_poem(analysis_results, poem_type, emphasis)
        
        # Store the generated poem in the session
        session[f'poem_{analysis_id}'] = poem
        
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
        
        if not analysis_id:
            return jsonify({'error': 'Invalid or expired analysis ID'}), 400
        
        if f'image_{analysis_id}' not in session or f'poem_{analysis_id}' not in session:
            return jsonify({'error': 'Image or poem data not found'}), 400
        
        # Get the image and poem data from the session
        image_data = session[f'image_{analysis_id}']
        poem = session[f'poem_{analysis_id}']
        
        # Get the frame selection from the request
        frame_style = data.get('frameStyle', 'classic')
        
        # Create the framed image with the poem
        final_image = create_framed_image(
            base64.b64decode(image_data), 
            poem, 
            frame_style
        )
        
        # Convert the final image to base64 for sending to the client
        final_image_base64 = base64.b64encode(final_image).decode('utf-8')
        
        return jsonify({
            'success': True,
            'finalImage': final_image_base64
        })
    
    except Exception as e:
        logger.error(f"Error creating final image: {str(e)}", exc_info=True)
        return jsonify({'error': f'Failed to create final image: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
