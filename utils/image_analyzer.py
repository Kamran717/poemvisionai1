import os
import io
import logging
from google.cloud import vision

# Set up logging
logger = logging.getLogger(__name__)

def analyze_image(image_file):
    """
    Analyze an image using Google Cloud Vision AI.
    
    Args:
        image_file: The image file to analyze (file object)
        
    Returns:
        dict: A dictionary containing the analysis results
    """
    try:
        # Reset file pointer to the beginning
        image_file.seek(0)
        
        # Create a client for the Vision API
        client = vision.ImageAnnotatorClient()
        
        # Read the image
        content = image_file.read()
        image = vision.Image(content=content)
        
        # Request various features
        features = [
            vision.Feature(type_=vision.Feature.Type.LABEL_DETECTION, max_results=15),
            vision.Feature(type_=vision.Feature.Type.FACE_DETECTION, max_results=10),
            vision.Feature(type_=vision.Feature.Type.OBJECT_LOCALIZATION, max_results=15),
            vision.Feature(type_=vision.Feature.Type.LANDMARK_DETECTION, max_results=5),
            vision.Feature(type_=vision.Feature.Type.IMAGE_PROPERTIES),
            vision.Feature(type_=vision.Feature.Type.SAFE_SEARCH_DETECTION)
        ]
        
        # Perform the API request
        response = client.annotate_image({
            'image': image,
            'features': features,
        })
        
        # Process the results
        results = {}
        
        # Process labels
        results['labels'] = []
        for label in response.label_annotations:
            results['labels'].append({
                'description': label.description,
                'score': round(label.score * 100, 2)
            })
        
        # Process faces
        results['faces'] = []
        for face in response.face_annotations:
            results['faces'].append({
                'joy': face.joy_likelihood.name,
                'sorrow': face.sorrow_likelihood.name,
                'anger': face.anger_likelihood.name,
                'surprise': face.surprise_likelihood.name,
                'headwear': face.headwear_likelihood.name
            })
        
        # Process objects
        results['objects'] = []
        for obj in response.localized_object_annotations:
            results['objects'].append({
                'name': obj.name,
                'score': round(obj.score * 100, 2)
            })
        
        # Process landmarks
        results['landmarks'] = []
        for landmark in response.landmark_annotations:
            results['landmarks'].append({
                'description': landmark.description,
                'score': round(landmark.score * 100, 2)
            })
        
        # Process image properties (colors)
        results['colors'] = []
        if response.image_properties:
            colors = response.image_properties.dominant_colors.colors
            for color in colors[:5]:  # Top 5 colors
                rgb = color.color
                hex_color = f'#{rgb.red:02x}{rgb.green:02x}{rgb.blue:02x}'
                results['colors'].append({
                    'hex': hex_color,
                    'score': round(color.score * 100, 2)
                })
        
        # Process safe search
        if response.safe_search_annotation:
            results['safe_search'] = {
                'adult': response.safe_search_annotation.adult.name,
                'medical': response.safe_search_annotation.medical.name,
                'violence': response.safe_search_annotation.violence.name
            }
        
        logger.debug(f"Image analysis results: {results}")
        return results
    
    except Exception as e:
        logger.error(f"Error analyzing image: {str(e)}", exc_info=True)
        raise
