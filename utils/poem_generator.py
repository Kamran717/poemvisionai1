import os
import logging
import requests
import json
import random

# Set up logging
logger = logging.getLogger(__name__)

# Get the API key from environment variable
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
# Updated to use v1 API instead of v1beta since the endpoint has changed
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent"

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
    ],
    "twinkle": [
        "sparkling", "twinkling", "shining", "glimmering", "glistening",
        "gleaming", "dazzling", "luminous", "magical", "bright"
    ],
    "roses": [
        "vivid", "colorful", "charming", "playful", "classic", 
        "romantic", "witty", "clever", "traditional", "catchy"
    ],
    "knock-knock": [
        "funny", "cheeky", "silly", "playful", "jolly", "comical",
        "witty", "ridiculous", "amusing", "quirky"
    ],
    "pickup": [
        "charming", "flirty", "smooth", "humorous", "cheeky",
        "clever", "witty", "bold", "playful", "daring"
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
    ],
    "twinkle": [
        "Twinkle, twinkle, {element1},\nHow I wonder what you are.\nUp above the {element2} so high,\nLike a {adj1} {element3} in the sky.\nTwinkle, twinkle, {element1},\nHow {adj2} you really are.",
        
        "Twinkle, twinkle, little {element1},\n{adj1} wonder in the night.\nOver {element2}, beyond {element3},\nSuch a {adj2}, {adj3} sight.\nTwinkle, twinkle, little {element1},\nGuide us with your gentle light."
    ],
    "roses": [
        "Roses are red,\n{element1}s are {adj1},\nWhen I see {element2},\nI think of you.\nWith {element3} so {adj2},\nAnd moments so true,\nLife is better,\nWith you in the crew.",
        
        "Roses are red,\n{element1}s are blue,\n{element2} is {adj1},\nAnd so are you.\nWith {element3} around,\nAnd skies so {adj2},\nThis poem sounds better,\nThan it probably should do."
    ],
    "knock-knock": [
        "Knock, knock!\nWho's there?\n{element1}.\n{element1} who?\n{element1} you glad I didn't say {element2}?\nThe {element3} is {adj1} and {adj2},\nJust like this silly rhyme!",
        
        "Knock, knock!\nWho's there?\n{element1} and {element2}.\n{element1} and {element2} who?\nI didn't know {element3} could be so {adj1} and {adj2}!\nNow that's a joke you won't forget!"
    ],
    "pickup": [
        "Are you a {element1}? Because you've got me feeling {adj1}.\nIf {element2} could talk, they'd say you're {adj2}.\nI'd cross an ocean of {element3} just to meet someone like you.\nCall me cheesy, but this pickup line was inspired by your photo!",
        
        "Is your name {element1}? Because you're absolutely {adj1}.\nDo you believe in love at first {element2}?\nBecause my heart just went {adj2} when I saw you.\nI've been looking for {element3} all my life, but you're even better.\nThis poem is smoother than my actual pickup lines!"
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
        try:
            logger.info(f"Sending request to Gemini API with prompt of length {len(prompt)}")
            response = requests.post(
                f"{GEMINI_API_URL}?key={GEMINI_API_KEY}",
                headers=headers,
                json=data,
                timeout=15  # Set a 15-second timeout
            )
            
            # Process the response
            if response.status_code == 200:
                response_data = response.json()
                logger.debug(f"Received successful response from Gemini API")
                
                # Extract the poem from the response
                if 'candidates' in response_data and len(response_data['candidates']) > 0:
                    if 'content' in response_data['candidates'][0] and 'parts' in response_data['candidates'][0]['content']:
                        parts = response_data['candidates'][0]['content']['parts']
                        if parts and 'text' in parts[0]:
                            generated_text = parts[0]['text']
                            return generated_text.strip()
                
                # If we get here, the response structure was unexpected
                logger.error(f"Unexpected response structure: {json.dumps(response_data)[:500]}...")
                return _generate_template_poem(analysis_results, poem_type, emphasis)
            else:
                logger.error(f"API error: {response.status_code} - {response.text[:200]}...")
                # Log the request that was sent for debugging
                logger.error(f"Request data: {json.dumps(data)[:500]}...")
                return _generate_template_poem(analysis_results, poem_type, emphasis)
        except requests.exceptions.Timeout:
            logger.error("Gemini API request timed out")
            return _generate_template_poem(analysis_results, poem_type, emphasis)
        except requests.exceptions.RequestException as e:
            logger.error(f"Request exception when calling Gemini API: {str(e)}")
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
    prompt = f"You are a master poet renowned for your extraordinary ability to craft beautiful, profound poetry. Create a stunning {poem_type} poem based on an image. Channel the style of the great poets while maintaining your unique voice. "
    
    # Add information about what's in the image
    if 'labels' in analysis_results and analysis_results['labels']:
        labels_text = ", ".join([label['description'] for label in analysis_results['labels'][:8]])
        prompt += f"The image contains: {labels_text}. "
    
    # Add information about objects
    if 'objects' in analysis_results and analysis_results['objects']:
        objects_text = ", ".join([obj['name'] for obj in analysis_results['objects'][:5]])
        prompt += f"Specific objects visible include: {objects_text}. "
    
    # Count people in the image using a more accurate approach
    people_count = 0
    has_faces = False
    
    # First check faces detected by the API
    faces_count = 0  # Initialize the variable to avoid "possibly unbound" error
    if 'faces' in analysis_results and analysis_results['faces']:
        faces_count = len(analysis_results['faces'])
        people_count = faces_count
        has_faces = True
    
    # Check if Person objects were detected
    if 'objects' in analysis_results and analysis_results['objects']:
        # Get confidence scores for Person objects
        person_scores = [obj['score'] for obj in analysis_results['objects'] if obj['name'] == 'Person']
        
        # Count unique Person objects with score > 70 to avoid duplicates and low-confidence detections
        high_confidence_people = sum(1 for score in person_scores if score > 70)
        
        # Count Person objects with scores between 50-70 as possibly the same people
        medium_confidence_people = sum(1 for score in person_scores if 50 <= score <= 70) // 2
        
        # Use face count as minimum, object detection as maximum
        # This avoids double-counting the same person from different angles
        total_person_objects = high_confidence_people + medium_confidence_people
        
        # If we see person objects but no faces, use object detection count
        if not has_faces:
            people_count = total_person_objects
        else:
            # If we have both faces and objects, use the more reliable count
            # but prevent excessive overcounting
            people_count = min(total_person_objects, faces_count + 1)
    
    # Add information about people and emotions
    if people_count > 0:
        # Mention people are the main focus of the image
        if people_count == 1:
            prompt += "There is one person in the image who is a central focus of the scene"
        else:
            prompt += f"There are {people_count} people in the image who are central to the scene"
        
        # Add emotions if available from face detection
        if has_faces:
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
        "love": "Craft a deeply romantic and heartfelt masterpiece that captures the essence of profound connection. Channel the passion of Pablo Neruda, the intimacy of Elizabeth Barrett Browning, and the emotional depth of Rumi. Explore the intricate interplay of desire, devotion, and the eternal nature of true love.",
        "funny": "Create a brilliantly humorous poem with the wit of Ogden Nash, the playful charm of Shel Silverstein, and the clever comedic timing of Dorothy Parker. Employ unexpected twists, delightful wordplay, and subtle irony that brings genuine smiles and laughter.",
        "inspirational": "Compose an uplifting masterpiece in the tradition of Maya Angelou, Rumi, and Walt Whitman that stirs the soul and ignites inner strength. Weave powerful metaphors of resilience, transformation, and the triumph of the human spirit that will truly motivate and inspire.",
        "angry": "Forge an intense, passionate work reminiscent of Sylvia Plath and Dylan Thomas that expresses powerful emotions with raw honesty. Create controlled chaos with deliberate rhythms, scorching metaphors, and precisely chosen words that convey genuine rage, frustration, and defiance.",
        "extreme": "Craft a revolutionary poem that shatters conventions like the works of Allen Ginsberg and Vladimir Mayakovsky. Use ALL CAPS for emphasis, experimental typography, violent imagery, and shocking juxtapositions. Break traditional forms, syntax, and expectations with explosive language that provokes and challenges.",
        "holiday": "Create an enchanting seasonal masterpiece that captures the festive spirit, traditions, and emotional resonance of holidays. Blend nostalgia, celebration, and the unique atmosphere of special occasions with rich, sensory details.",
        "birthday": "Compose a memorable celebration of life's journey with themes of growth, reflection, and joyful milestones. Balance the personal significance of aging with universal insights about the passage of time and the gifts each year brings.",
        "anniversary": "Craft an exquisite tribute to enduring love and commitment in the tradition of Elizabeth Barrett Browning and Pablo Neruda. Explore the depth of shared experiences, the beauty of lasting connection, and the precious nature of time spent together.",
        "nature": "Create a sensory-rich nature poem in the tradition of Mary Oliver, William Wordsworth, and Robert Frost that reveals the profound beauty, wisdom, and tranquility found in the natural world. Use precise observations and reverent language to elevate the ordinary to the sublime.",
        "friendship": "Compose a heartfelt celebration of profound human connection that explores the depth, loyalty, and transformative power of true friendship. Weave together moments of joy, support through darkness, and the unique understanding that exists between kindred spirits.",
        "free verse": "Craft an organic, flowing masterpiece in the tradition of Walt Whitman, T.S. Eliot, and Pablo Neruda that breaks free from conventional rhyme schemes and meters. Allow rhythm to emerge naturally from emotional intensity and the inherent music of carefully chosen words.",
        "twinkle": "Create a whimsical, melodic poem in the style of 'Twinkle, Twinkle, Little Star.' Maintain the rhythm and structure of the classic nursery rhyme, but personalize it based on the image elements. Incorporate the distinctive 'Twinkle, twinkle' repetition at the beginning and end while creating a sense of wonder and childlike curiosity.",
        "roses": "Craft a clever variation of the classic 'Roses are red, violets are blue' poem format. Start with the iconic opening lines, then subvert expectations with surprising, witty, or meaningful follow-up lines that relate to the image. Maintain the simple rhyme scheme while adding personality and charm.",
        "knock-knock": "Create a playful knock-knock joke in poem form, incorporating elements from the image. Begin with the traditional 'Knock, knock / Who's there?' format, then craft a punchline that cleverly relates to the visual elements. Add a brief poetic conclusion that ties the joke together with the image's mood or theme.",
        "pickup": "Compose an intentionally cheesy but charming pickup line poem that creatively incorporates elements from the image. Balance humor and genuine compliments while maintaining a playful, flirtatious tone. Create lines that are memorable, witty, and just the right amount of over-the-top to bring a smile."
    }
    
    if poem_type in poem_type_instructions:
        prompt += poem_type_instructions[poem_type] + " "
    
    # Final formatting instructions
    prompt += "The poem should be 8-16 lines long. Use powerful, evocative language with rich metaphors and vivid imagery derived from what's in the image. "
    prompt += "Incorporate compelling rhythm and flow, with carefully chosen words that create musicality. Employ literary techniques like alliteration, assonance, or symbolism where appropriate. "
    prompt += "Make the poem profoundly emotionally resonant, thought-provoking, and meaningful with layers of interpretation. Do not include a title or any explanatory text, just the exquisite poem itself."
    
    return prompt
