import os
import logging
import requests
import json
import random

# Set up logging
logger = logging.getLogger(__name__)

# Get the API key from environment variable
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

# Poem adjectives by type
POEM_ADJECTIVES = {
    "default": [
        "beautiful", "vibrant", "gentle", "serene", "colorful", "vivid",
        "radiant", "peaceful", "delicate", "striking", "profound", "timeless"
    ],
    "love": [
        "tender", "passionate", "romantic", "intimate", "affectionate",
        "devoted", "cherished", "heartfelt", "adoring", "loving"
    ],
    "funny": [
        "whimsical", "quirky", "silly", "playful", "amusing", "witty",
        "comical", "humorous", "lighthearted", "ridiculous"
    ],
    "inspirational": [
        "uplifting", "empowering", "motivating", "encouraging", "hopeful",
        "triumphant", "resilient", "determined", "courageous", "strong"
    ],
    "angry": [
        "fierce", "furious", "intense", "raging", "seething", "bitter",
        "wrathful", "outraged", "fiery", "burning", "hostile", "vehement"
    ],
    "extreme": [
        "radical", "daring", "bold", "intense", "explosive", "audacious",
        "wild", "unrestrained", "ferocious", "relentless", "boundless", "savage"
    ],
    "holiday": [
        "festive", "merry", "joyous", "celebratory", "cheerful", "bright",
        "wondrous", "magical", "traditional", "nostalgic"
    ],
    "birthday": [
        "festive", "joyful", "celebratory", "special", "memorable",
        "milestone", "hopeful", "cheerful", "delightful", "happy"
    ],
    "anniversary": [
        "enduring", "devoted", "faithful", "committed", "treasured",
        "everlasting", "steadfast", "cherished", "timeless", "loving"
    ]
}

# Poem templates by type
POEM_TEMPLATES = {
    "default": [
        "In the world of {element1} and {element2},\nA {adj1} moment caught in time.\nThe {adj2} {element3} speaks to me,\nIn a language {adj3} and sublime.",
        
        "I gaze upon the {element1},\n{adj1} and {adj2} in the light.\nThe {element2} brings to mind\nThoughts both {adj3} and bright.",
        
        "This image shows a {adj1} scene,\nWhere {element1} meets {element2}.\nThe {element3} stands in {adj2} repose,\nA moment {adj3} and true.",
        
        "Look closely at the {element1},\nSo {adj1} in its grace.\nThe {element2} and {element3} combine,\nTo create a {adj2} space.",
        
        "From every angle, {adj1} beauty shines,\nThe {element1} tells a story untold.\nWith {element2} and {element3} intertwined,\nA {adj2} vision to behold."
    ],
    "love": [
        "In your eyes, I see {element1},\nYour smile, like {element2}, {adj1} and bright.\nOur love, a {adj2} {element3},\nShines through the darkest night.",
        
        "Two hearts like {element1},\n{adj1}, {adj2}, forever true.\nLike {element2} and {element3} together,\nMy heart belongs to you."
    ],
    "funny": [
        "The {element1} looked so {adj1},\nIt nearly made me sneeze.\nThe {element2} danced with {element3},\nWith {adj2} expertise.",
        
        "Oh {element1}, you're so {adj1},\nLike {element2} on a stick.\nYou make me laugh like {element3},\nIt's really quite {adj2}!"
    ],
    "inspirational": [
        "Rise like the {element1}, {adj1} and strong,\nLet your spirit soar like {element2}.\nFace each challenge, each {element3},\nWith courage {adj2} and true.",
        
        "Within you lies the power of {element1},\n{adj1}, {adj2}, without end.\nLet {element2} guide your journey,\nAnd {element3} be your friend."
    ],
    "angry": [
        "The {element1} burns with {adj1} rage,\nAs {element2} crushes all in sight.\nNo mercy for the {element3},\nIn this {adj2}, relentless night.",
        
        "How dare the {element1} stand so tall,\n{adj1} and {adj2} in its might.\nThe {element2} mocks the {element3},\nWith contempt so bright."
    ],
    "extreme": [
        "The {element1} EXPLODES through boundaries,\n{adj1}, {adj2}, breaking all chains!\nThe {element2} SMASHES into {element3},\nNo rules or limits remain!",
        
        "BEHOLD the {adj1} {element1},\nDEFYING gravity and time!\nThe {element2} COLLIDES with {element3},\nIn a {adj2} paradigm!"
    ],
    "holiday": [
        "Celebrate with {element1} and cheer,\nThis {adj1} holiday time.\nWith {element2} and {element3} all around,\nEverything feels {adj2} and prime.",
        
        "The season brings us {element1},\n{adj1} moments to treasure and keep.\n{element2} and {element3} fill the air,\nMaking memories {adj2} and deep."
    ],
    "birthday": [
        "Another year, like {element1}, has passed,\nFilled with moments {adj1} and {adj2}.\nMay your new year bring {element2},\nAnd {element3} the whole year through.",
        
        "Today we celebrate your {element1},\nWith joy both {adj1} and {adj2}.\nMay {element2} and {element3} follow you,\nIn everything you do."
    ],
    "anniversary": [
        "Years together, like {element1} and {element2},\nA bond both {adj1} and {adj2}.\nOur love, a {element3} that never fades,\nGrows stronger, between me and you.",
        
        "Our journey, like {element1},\nContinues {adj1} and {adj2}.\nWith {element2} and {element3} we've shared,\nOur love remains forever true."
    ]
}

def generate_poem(analysis_results, poem_type, emphasis):
    """
    Generate a poem based on image analysis and user preferences using Google's Gemini API.
    If the API is not available, generates a basic poem using templates.
    
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
            logger.warning("Gemini API key not found in environment variables. Using template poem.")
            return _generate_template_poem(analysis_results, poem_type, emphasis)
        
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
                return _generate_template_poem(analysis_results, poem_type, emphasis)
        else:
            logger.error(f"API error: {response.status_code} - {response.text}")
            return _generate_template_poem(analysis_results, poem_type, emphasis)
    
    except Exception as e:
        logger.error(f"Error generating poem: {str(e)}", exc_info=True)
        return _generate_template_poem(analysis_results, poem_type, emphasis)

def _generate_template_poem(analysis_results, poem_type, emphasis):
    """
    Generate a poem based on templates when the API is not available.
    
    Args:
        analysis_results (dict): The results from the image analysis
        poem_type (str): The type of poem to generate
        emphasis (list): List of elements to emphasize in the poem
        
    Returns:
        str: The generated poem
    """
    # Extract elements from analysis to use in the poem
    all_elements = []
    
    # Add labels
    if 'labels' in analysis_results and analysis_results['labels']:
        all_elements.extend([label['description'] for label in analysis_results['labels'][:8]])
    
    # Add objects
    if 'objects' in analysis_results and analysis_results['objects']:
        all_elements.extend([obj['name'] for obj in analysis_results['objects'][:5]])
    
    # Add landmarks
    if 'landmarks' in analysis_results and analysis_results['landmarks']:
        all_elements.extend([landmark['description'] for landmark in analysis_results['landmarks']])
    
    # If emphasis elements are provided, prioritize those
    if emphasis:
        emphasized_elements = emphasis.copy()
        for element in all_elements:
            if element not in emphasized_elements:
                emphasized_elements.append(element)
        all_elements = emphasized_elements
    
    # Ensure we have at least some elements to work with
    if not all_elements:
        all_elements = ["image", "moment", "beauty", "time", "art", "vision", "feeling"]
    
    # Get a few key elements for the poem
    key_elements = all_elements[:min(4, len(all_elements))]
    
    # Sample from poem templates based on the poem type
    return _apply_poem_template(key_elements, poem_type)

def _apply_poem_template(key_elements, poem_type):
    """
    Apply a template to generate a poem based on the key elements and poem type.
    
    Args:
        key_elements (list): List of key elements to include in the poem
        poem_type (str): The type of poem to generate
        
    Returns:
        str: The generated poem
    """
    # Get poem adjectives based on poem type
    adjectives = POEM_ADJECTIVES.get(poem_type.lower(), POEM_ADJECTIVES["default"])
    
    # Get poem templates based on the poem type
    templates = POEM_TEMPLATES.get(poem_type.lower(), POEM_TEMPLATES["default"])
    
    # Randomly select a template
    template = random.choice(templates)
    
    # Replace placeholders with key elements and adjectives
    for i, element in enumerate(key_elements):
        if i < 4:  # Only use up to 4 elements
            placeholder = f"{{element{i+1}}}"
            template = template.replace(placeholder, element.lower())
    
    # Replace adjective placeholders
    for i, adj in enumerate(random.sample(adjectives, min(4, len(adjectives)))):
        if i < 4:  # Only use up to 4 adjectives
            placeholder = f"{{adj{i+1}}}"
            template = template.replace(placeholder, adj)
    
    return template

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
        "angry": "Make the poem intense and passionate, expressing rage, frustration, and strong emotions. Use forceful language and imagery.",
        "extreme": "Create a bold, intense poem that breaks conventions. Use ALL CAPS for emphasis, dramatic punctuation, and powerful imagery. Be daring and excessive!",
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
