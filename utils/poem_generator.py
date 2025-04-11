import os
import logging
import requests
import json

# Set up logging
logger = logging.getLogger(__name__)

# Get the API key from environment variable
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

def generate_poem(analysis_results, poem_type, emphasis):
    """
    Generate a poem based on image analysis and user preferences using Google's Gemini API.
    
    Args:
        analysis_results (dict): The results from the Google Cloud Vision AI analysis
        poem_type (str): The type of poem to generate (e.g., 'love', 'funny', 'inspirational')
        emphasis (list): List of elements to emphasize in the poem
        
    Returns:
        str: The generated poem
    """
    try:
        # Check if API key is available
        if not GEMINI_API_KEY:
            logger.error("Gemini API key not found in environment variables")
            return "Error: API key not configured. Please set the GEMINI_API_KEY environment variable."
        
        # Create a detailed prompt based on the analysis and user preferences
        prompt = _create_prompt(analysis_results, poem_type, emphasis)
        logger.debug(f"Generated prompt: {prompt}")
        
        # Prepare the API request
        headers = {
            "Content-Type": "application/json",
        }
        
        data = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }],
            "generationConfig": {
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 800,
            }
        }
        
        # Make the API request
        response = requests.post(
            f"{GEMINI_API_URL}?key={GEMINI_API_KEY}",
            headers=headers,
            json=data
        )
        
        # Process the response
        if response.status_code == 200:
            response_data = response.json()
            
            # Extract the poem from the response
            if 'candidates' in response_data and len(response_data['candidates']) > 0:
                generated_text = response_data['candidates'][0]['content']['parts'][0]['text']
                return generated_text.strip()
            else:
                logger.error(f"Unexpected response structure: {response_data}")
                return "Error: Unable to generate poem. Unexpected response structure."
        else:
            logger.error(f"API error: {response.status_code} - {response.text}")
            return f"Error: Unable to generate poem. API returned status code {response.status_code}."
    
    except Exception as e:
        logger.error(f"Error generating poem: {str(e)}", exc_info=True)
        return f"Error: Unable to generate poem. {str(e)}"

def _create_prompt(analysis_results, poem_type, emphasis):
    """
    Create a detailed prompt for the LLM based on image analysis and user preferences.
    
    Args:
        analysis_results (dict): The results from the Google Cloud Vision AI analysis
        poem_type (str): The type of poem to generate (e.g., 'love', 'funny', 'inspirational')
        emphasis (list): List of elements to emphasize in the poem
        
    Returns:
        str: The generated prompt
    """
    # Start with the basic instruction
    prompt = f"Write a beautiful {poem_type} poem based on an image. "
    
    # Add information about what's in the image
    if 'labels' in analysis_results and analysis_results['labels']:
        labels_text = ", ".join([label['description'] for label in analysis_results['labels'][:8]])
        prompt += f"The image contains: {labels_text}. "
    
    # Add information about objects
    if 'objects' in analysis_results and analysis_results['objects']:
        objects_text = ", ".join([obj['name'] for obj in analysis_results['objects'][:5]])
        prompt += f"Specific objects visible include: {objects_text}. "
    
    # Add information about faces and emotions
    if 'faces' in analysis_results and analysis_results['faces']:
        faces_count = len(analysis_results['faces'])
        if faces_count == 1:
            prompt += "There is one person in the image"
        elif faces_count > 1:
            prompt += f"There are {faces_count} people in the image"
            
        # Add emotions if available
        emotions = []
        for face in analysis_results['faces']:
            for emotion in ['joy', 'sorrow', 'anger', 'surprise']:
                if face[emotion] in ['LIKELY', 'VERY_LIKELY']:
                    emotions.append(emotion)
        
        if emotions:
            emotions_text = ", ".join(emotions)
            prompt += f" showing emotions of {emotions_text}. "
        else:
            prompt += ". "
    
    # Add information about landmarks or locations
    if 'landmarks' in analysis_results and analysis_results['landmarks']:
        landmarks_text = ", ".join([landmark['description'] for landmark in analysis_results['landmarks']])
        prompt += f"The location appears to be: {landmarks_text}. "
    
    # Add information about emphasized elements
    if emphasis:
        emphasis_text = ", ".join(emphasis)
        prompt += f"Please emphasize these elements in the poem: {emphasis_text}. "
    
    # Add specific instructions based on poem type
    poem_type_instructions = {
        "love": "Make the poem romantic and heartfelt, focusing on emotions and connections.",
        "funny": "Make the poem humorous and light-hearted, perhaps using clever wordplay.",
        "inspirational": "Create an uplifting poem that motivates and inspires, focusing on strength and perseverance.",
        "holiday": "Capture the festive spirit and joy of holiday occasions.",
        "birthday": "Include themes of celebration, growth, and personal milestones.",
        "anniversary": "Focus on themes of enduring love, commitment, and shared memories.",
        "nature": "Emphasize the beauty and tranquility of natural elements in the image.",
        "friendship": "Highlight the bond of friendship, loyalty, and shared experiences.",
        "free verse": "Create a poem with no specific rhyme scheme or meter, focusing on imagery and emotion."
    }
    
    if poem_type in poem_type_instructions:
        prompt += poem_type_instructions[poem_type] + " "
    
    # Final formatting instructions
    prompt += "The poem should be 8-16 lines long. Use vivid imagery and sensory details based on what's in the image. "
    prompt += "Make the poem emotionally resonant and meaningful. Do not include a title or any explanatory text, just the poem itself."
    
    return prompt
