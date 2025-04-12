import os
import logging
import requests
import json
import random
import hashlib

# Set up logging
logger = logging.getLogger(__name__)

# Poem generation cache
_poem_cache = {}

# Get the API key from environment variable
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
# Update to use the correct API endpoint 
# The API might have changed, so we provide both v1beta and v1 endpoints
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
# Fallback URL if the main one doesn't work
GEMINI_API_URL_FALLBACK = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent"

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
    # Religious poem adjectives
    "religious-islam": [
        "reverent", "devout", "faithful", "pious", "spiritual", "blessed",
        "divine", "merciful", "humble", "sacred", "enlightened", "compassionate"
    ],
    "religious-christian": [
        "devout", "faithful", "blessed", "graceful", "divine", "prayerful",
        "sacred", "righteous", "holy", "reverent", "redeeming", "virtuous"
    ],
    "religious-judaism": [
        "faithful", "devotional", "traditional", "sacred", "wise", "righteous",
        "blessed", "honorable", "devout", "reverent", "divine", "covenant"
    ],
    "religious-general": [
        "spiritual", "transcendent", "divine", "celestial", "sacred", "mystical",
        "ethereal", "enlightened", "reverent", "blessed", "harmonious", "serene"
    ],
    # Memorial/RIP poem adjectives
    "memorial": [
        "reflective", "honoring", "remembering", "eternal", "respectful", "cherished",
        "commemorative", "treasured", "heartfelt", "solemn", "dignified", "enduring"
    ],
    # New categories
    "farewell": [
        "bittersweet", "poignant", "wistful", "gentle", "nostalgic", "reflective", 
        "hopeful", "tender", "grateful", "meaningful", "enduring", "soulful"
    ],
    "newborn": [
        "precious", "innocent", "tender", "pure", "miraculous", "delicate", 
        "joyful", "hopeful", "gentle", "wondrous", "fragile", "blessed"
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
    ],
    "haiku": [
        "simple", "elegant", "natural", "seasonal", "fleeting",
        "profound", "observant", "concise", "thoughtful", "gentle"
    ],
    "limerick": [
        "quirky", "playful", "humorous", "absurd", "rhythmic",
        "cheeky", "ridiculous", "entertaining", "catchy", "bouncy"
    ],
    "sonnet": [
        "elegant", "formal", "eloquent", "structured", "flowing",
        "timeless", "romantic", "sophisticated", "traditional", "refined"
    ],
    "rap": [
        "bold", "rhythmic", "urban", "expressive", "powerful",
        "street", "dynamic", "intense", "authentic", "flowing"
    ],
    "nursery": [
        "childlike", "playful", "innocent", "simple", "rhythmic",
        "bouncy", "whimsical", "catchy", "cheerful", "melodic"
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
    ],
    "haiku": [
        "{element1} in light\n{element2} {adj1} and {adj2}\n{element3} remains",
        
        "{adj1} {element1}\n{element2} meets {element3}\n{adj2} moment now"
    ],
    "limerick": [
        "There once was a {adj1} {element1},\nWho found itself next to {element2}.\nWith {adj2} delight,\nWhat a wonderful sight,\nAs it danced with a {adj3} {element3}!",
        
        "A {element1} so {adj1} and bright,\nGave {element2} an incredible fright.\nWith {element3} nearby,\nIt made them all sigh,\nIn a manner both {adj2} and light!"
    ],
    "sonnet": [
        "The {adj1} {element1} stands in quiet grace,\nWhile {element2} moves in patterns yet unseen.\nThe {adj2} light reveals each perfect trace,\nOf {element3} that has forever been.\n\nThrough time and change some things remain the same,\nThe {adj3} beauty lasting through the years.\nNo words could ever truly frame,\nThe depth of what an image now appears.",
        
        "When first I saw the {adj1} {element1},\nI thought of how {element2} seemed to glow.\nThe {adj2} light made {element3} shine,\nIn ways that few would ever know.\n\nIn this brief moment captured here,\nA {adj3} world appears for all to see."
    ],
    "rap": [
        "Yo! Check out the {element1}, so {adj1} and true,\nWith the {element2} in the back, I'm tellin' you!\nThis {adj2} {element3} is straight up fire,\nDroppin' beats and rhymes to inspire!",
        
        "Listen up! I've got the {adj1} flow,\nSeein' {element1} and {element2}, you already know!\nThe {adj2} {element3} is keepin' it real,\nThis image has got that authentic feel!"
    ],
    "nursery": [
        "{adj1}, {adj1} {element1},\nHow does your {element2} grow?\nWith {adj2} {element3} and pretty bells,\nAll lined up in a row.",
        
        "{element1}, {element1}, {adj1} and bright,\nSitting with {element2} tonight.\nThe {adj2} {element3} went round and round,\nAs they all played out of sight."
    ],
    
    # Religious poem templates
    "religious-islam": [
        "In the light of {element1}, I find peace,\nAs {adj1} as the morning prayer.\nThe {element2} reminds me of divine mercy,\nAllah's guidance is everywhere.\nThrough {element3}, {adj2} and true,\nI witness the Creator's care.",
        
        "Bismillah, I begin with {element1},\n{adj1} signs of the Most Merciful.\nThe {element2} and {element3} before me,\nCreations so {adj2} and beautiful.\nSubhanAllah, in everything I see,\nThe wonder of the Divine's will."
    ],
    
    "religious-christian": [
        "The Lord created {element1},\nSo {adj1} in His perfect design.\nLike {element2} speaking to my soul,\nHis love is {adj2} and divine.\nThrough {element3} I feel His presence,\nHis grace forever mine.",
        
        "As I gaze upon the {element1},\nI feel God's {adj1} embrace.\nThe {element2} reminds me of His word,\nFilled with {adj2} amazing grace.\nIn {element3} I see His glory,\nAnd His mercy I can trace."
    ],
    
    "religious-judaism": [
        "Like ancient wisdom, {element1} stands,\n{adj1} as the covenant of old.\nThe {element2} speaks of traditions kept,\nStories {adj2} and bold.\nFrom generation to generation,\nLike {element3}, our faith unfolds.",
        
        "Shalom brings {element1} to my heart,\n{adj1} as the Sabbath light.\nThe {element2} reminds me of Torah's truth,\nGuiding with wisdom {adj2} and bright.\nLike {element3} before the Eternal One,\nWe stand in awe of divine might."
    ],
    
    "religious-general": [
        "The {adj1} spirit moves through {element1},\nLike prayers rising to the sky.\nIn {element2} I feel the sacred pulse,\nA connection {adj2} and high.\nThe divine speaks through {element3},\nIn a language that cannot lie.",
        
        "Beyond the veil of {element1},\nLies truth both {adj1} and vast.\nThe soul, like {element2}, seeks the light,\nIn moments {adj2} and steadfast.\nThrough {element3} we glimpse eternity,\nWhere material concerns are surpassed."
    ],
    
    # Memorial poem templates
    "memorial": [
        "In loving memory of days with {element1},\nNow {adj1} in our hearts you stay.\nYour smile, like {element2}, we remember,\nIn a {adj2}, gentle way.\nThrough {element3} your spirit lingers,\nThough from earth you've gone away.",
        
        "We remember you through {element1},\n{adj1} memories that never fade.\nLike {element2}, your light still shines,\n{adj2} love that you conveyed.\nIn {element3} we feel your presence,\nThe legacy of life you made."
    ],
    
    # Farewell poem templates
    "farewell": [
        "As paths diverge like {element1},\nI bid farewell with thoughts {adj1} and true.\nOur memories, bright as {element2},\nRemain {adj2} through and through.\nMay {element3} guide your journey ahead,\nUntil our paths cross anew.",
        
        "The time has come to say goodbye,\nLike {element1}, {adj1} yet bittersweet.\nThe {element2} reminds me of our days,\nWith moments {adj2} and fleet.\nThrough {element3} I send my parting wish,\nFor fortune you will meet."
    ],
    
    # Newborn poem templates
    "newborn": [
        "Welcome little one, like {element1},\nSo {adj1} and new to this world.\nYour eyes shine brighter than {element2},\nAs your story becomes {adj2} unfurled.\nLike {element3}, full of wonder and promise,\nA precious life has been uncurled.",
        
        "A miracle arrives like {element1},\n{adj1} and perfect in every way.\nTiny fingers reach for {element2},\nIn a {adj2}, gentle sway.\nWith {element3} watching over you,\nYou grow stronger each new day."
    ]
}

def generate_poem(analysis_results, poem_type, emphasis, custom_terms='', custom_category=''):
    """
    Generate a poem based on image analysis and user preferences using Google's Gemini API.
    If the API is not available, generates a basic poem using templates.
    Includes caching to improve performance for repeated requests.
    
    Args:
        analysis_results (dict): The results from the Google Cloud Vision AI analysis
        poem_type (str): The type of poem to generate (e.g., 'love', 'funny', 'inspirational')
        emphasis (list): List of elements to emphasize in the poem
        custom_terms (str, optional): Custom terms or names to include in the poem
        custom_category (str, optional): Category of the custom terms (e.g., names, places)
        
    Returns:
        str: The generated poem
    """
    try:
        # Create a unique cache key based on all inputs
        # First, convert emphasis list to a stable string representation
        emphasis_str = ','.join(sorted(emphasis)) if emphasis else 'none'
        
        # Create a simplified version of analysis_results that contains only the essential elements
        # This makes the cache key more stable across similar images
        simple_analysis = {}
        if 'labels' in analysis_results:
            simple_analysis['labels'] = [label['description'] for label in analysis_results['labels'][:5]]
        if 'objects' in analysis_results:
            simple_analysis['objects'] = [obj['name'] for obj in analysis_results['objects'][:5]]
        
        # Create a hash of all the inputs
        cache_key_data = {
            'analysis': simple_analysis,
            'poem_type': poem_type,
            'emphasis': emphasis_str,
            'custom_terms': custom_terms,
            'custom_category': custom_category
        }
        
        # Convert to string and hash
        cache_key = hashlib.md5(json.dumps(cache_key_data, sort_keys=True).encode('utf-8')).hexdigest()
        
        # Check if we have a cached poem for this input
        if cache_key in _poem_cache:
            logger.info(f"Using cached poem for key: {cache_key[:8]}...")
            return _poem_cache[cache_key]
        
        # Check if API key is available
        if not GEMINI_API_KEY:
            logger.warning("Gemini API key not found in environment variables. Using template poem.")
            poem = _generate_template_poem(analysis_results, poem_type, emphasis, custom_terms, custom_category)
            # Store in cache before returning
            _poem_cache[cache_key] = poem
            return poem
        
        # Create a detailed prompt based on the analysis and user preferences
        prompt = _create_prompt(analysis_results, poem_type, emphasis, custom_terms, custom_category)
        logger.debug(f"Generated prompt: {prompt}")
        
        # Prepare the API request with enhanced parameters for poetry generation
        headers = {
            "Content-Type": "application/json",
        }
        
        # Specifically tune parameters for poetry:
        # - Increased temperature for more creative language
        # - Higher topK to consider more diverse word choices
        # - Slightly reduced topP to focus on more likely language constructs for poetry
        # - Increased maxOutputTokens to allow for longer, more expressive poems
        data = {
            "contents": [{
                "parts": [{
                    "text": prompt
                }]
            }],
            "generationConfig": {
                "temperature": 0.85,  # Higher temperature for more creative, diverse outputs
                "topK": 60,           # Consider more options for each token
                "topP": 0.92,         # Slightly more focused than default
                "maxOutputTokens": 1000, # More space for poetic expression
                "stopSequences": ["Title:", "--", "###"], # Prevent the model from adding titles or separators
            },
            "safetySettings": [
                # Keep these relatively permissive for poetic expression while preventing harmful content
                {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
                {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
                {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
                {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"}
            ]
        }
        
        # Make the API request - try the main endpoint first, then the fallback
        try:
            # First attempt with primary endpoint (v1beta)
            logger.info(f"Sending request to Gemini API (primary endpoint) with prompt of length {len(prompt)}")
            response = requests.post(
                f"{GEMINI_API_URL}?key={GEMINI_API_KEY}",
                headers=headers,
                json=data,
                timeout=15  # Set a 15-second timeout
            )
            
            # If main endpoint fails with 404, try the fallback endpoint
            if response.status_code == 404:
                logger.warning("Primary Gemini API endpoint returned 404, trying fallback endpoint")
                response = requests.post(
                    f"{GEMINI_API_URL_FALLBACK}?key={GEMINI_API_KEY}",
                    headers=headers,
                    json=data,
                    timeout=15
                )
            
            # Process the response with enhanced error handling and parsing
            if response.status_code == 200:
                try:
                    response_data = response.json()
                    logger.debug(f"Received successful response from Gemini API")
                    
                    # Extract the poem from the response
                    # Handling multiple possible response formats
                    
                    # Format 1: v1beta API format
                    if 'candidates' in response_data and len(response_data['candidates']) > 0:
                        if 'content' in response_data['candidates'][0] and 'parts' in response_data['candidates'][0]['content']:
                            parts = response_data['candidates'][0]['content']['parts']
                            if parts and 'text' in parts[0]:
                                generated_text = parts[0]['text']
                                # Clean up the poem - remove any title-like elements
                                poem_lines = generated_text.strip().split('\n')
                                
                                # If the first line looks like a title (short, possibly followed by empty line)
                                if len(poem_lines) > 2 and len(poem_lines[0]) < 50 and not poem_lines[1].strip():
                                    poem_lines = poem_lines[2:]  # Skip potential title and blank line
                                
                                # Join the remaining lines
                                poem = '\n'.join(poem_lines).strip()
                                
                                # Post-process: clean up extra quotation marks at beginning/end that the model sometimes adds
                                poem = poem.strip('"')
                                
                                # Store in cache before returning
                                _poem_cache[cache_key] = poem
                                logger.info(f"Stored poem in cache with key: {cache_key[:8]}...")
                                return poem
                    
                    # Format 2: Alternative API format
                    elif 'result' in response_data and 'response' in response_data['result']:
                        generated_text = response_data['result']['response'].strip()
                        # Clean up the poem - remove any title-like elements
                        poem_lines = generated_text.strip().split('\n')
                        
                        # If the first line looks like a title (short, possibly followed by empty line)
                        if len(poem_lines) > 2 and len(poem_lines[0]) < 50 and not poem_lines[1].strip():
                            poem_lines = poem_lines[2:]  # Skip potential title and blank line
                        
                        # Join the remaining lines
                        poem = '\n'.join(poem_lines).strip()
                        
                        # Post-process: clean up extra quotation marks at beginning/end that the model sometimes adds
                        poem = poem.strip('"')
                        
                        # Store in cache before returning
                        _poem_cache[cache_key] = poem
                        logger.info(f"Stored poem in cache with key: {cache_key[:8]}...")
                        return poem
                    
                    # Format 3: Direct text in the response (simplified format)
                    elif 'text' in response_data:
                        generated_text = response_data['text'].strip()
                        # Clean up the poem - remove any title-like elements
                        poem_lines = generated_text.strip().split('\n')
                        
                        # If the first line looks like a title (short, possibly followed by empty line)
                        if len(poem_lines) > 2 and len(poem_lines[0]) < 50 and not poem_lines[1].strip():
                            poem_lines = poem_lines[2:]  # Skip potential title and blank line
                        
                        # Join the remaining lines
                        poem = '\n'.join(poem_lines).strip()
                        
                        # Post-process: clean up extra quotation marks at beginning/end that the model sometimes adds
                        poem = poem.strip('"')
                        
                        # Store in cache before returning
                        _poem_cache[cache_key] = poem
                        logger.info(f"Stored poem in cache with key: {cache_key[:8]}...")
                        return poem
                    
                    # More flexible search through the response for text content
                    else:
                        # Dump the response to string and search for it
                        response_str = json.dumps(response_data)
                        possible_poems = []
                        
                        # Look for common patterns in the response that might contain the poem
                        for key in ['text', 'content', 'message', 'poem', 'generated']:
                            if f'"{key}":' in response_str:
                                # Extract the content after this key
                                start_idx = response_str.find(f'"{key}":') + len(f'"{key}":')
                                if response_str[start_idx].strip() == '"':
                                    # It's a string value
                                    end_idx = response_str.find('"', start_idx + 1)
                                    while end_idx > 0 and response_str[end_idx-1] == '\\':
                                        end_idx = response_str.find('"', end_idx + 1)
                                    if end_idx > 0:
                                        possible_poems.append(response_str[start_idx+1:end_idx])
                        
                        if possible_poems:
                            # Use the longest poem found as likely the most complete
                            poem = max(possible_poems, key=len).strip()
                            # Clean up the poem - remove any title-like elements
                            poem_lines = poem.strip().split('\n')
                            
                            # If the first line looks like a title (short, possibly followed by empty line)
                            if len(poem_lines) > 2 and len(poem_lines[0]) < 50 and not poem_lines[1].strip():
                                poem_lines = poem_lines[2:]  # Skip potential title and blank line
                            
                            # Join the remaining lines
                            poem = '\n'.join(poem_lines).strip()
                            
                            # Post-process: clean up extra quotation marks at beginning/end that the model sometimes adds
                            poem = poem.strip('"')
                            
                            # Store in cache before returning
                            _poem_cache[cache_key] = poem
                            logger.info(f"Stored poem in cache with key: {cache_key[:8]}...")
                            return poem
                    
                    # If we get here, the response structure was unexpected
                    logger.error(f"Unexpected response structure: {json.dumps(response_data)[:500]}...")
                    poem = _generate_template_poem(analysis_results, poem_type, emphasis, custom_terms, custom_category)
                    # Store in cache before returning
                    _poem_cache[cache_key] = poem
                    logger.info(f"Stored template poem in cache with key: {cache_key[:8]}...")
                    return poem
                
                except (json.JSONDecodeError, KeyError, TypeError) as e:
                    # Error parsing the JSON response
                    logger.error(f"Error parsing API response: {str(e)}")
                    logger.error(f"Raw response: {response.text[:500]}...")
                    poem = _generate_template_poem(analysis_results, poem_type, emphasis, custom_terms, custom_category)
                    # Store in cache before returning
                    _poem_cache[cache_key] = poem
                    logger.info(f"Stored JSON parse error fallback poem in cache with key: {cache_key[:8]}...")
                    return poem
            else:
                logger.error(f"API error: {response.status_code} - {response.text[:200]}...")
                # Log the request that was sent for debugging
                logger.error(f"Request data: {json.dumps(data)[:500]}...")
                poem = _generate_template_poem(analysis_results, poem_type, emphasis, custom_terms, custom_category)
                # Store in cache before returning
                _poem_cache[cache_key] = poem
                logger.info(f"Stored fallback poem in cache with key: {cache_key[:8]}...")
                return poem
        except requests.exceptions.Timeout:
            logger.error("Gemini API request timed out")
            # Create a timeout-specific cache key
            timeout_key = hashlib.md5(f"timeout:{poem_type}:{str(emphasis)}:{custom_terms}".encode('utf-8')).hexdigest()
            poem = _generate_template_poem(analysis_results, poem_type, emphasis, custom_terms, custom_category)
            # Store in cache before returning
            _poem_cache[timeout_key] = poem
            logger.info(f"Stored timeout fallback poem in cache with key: {timeout_key[:8]}...")
            return poem
        except requests.exceptions.RequestException as e:
            logger.error(f"Request exception when calling Gemini API: {str(e)}")
            # Create a request error-specific cache key
            error_key = hashlib.md5(f"reqerror:{poem_type}:{str(emphasis)}:{custom_terms}".encode('utf-8')).hexdigest()
            poem = _generate_template_poem(analysis_results, poem_type, emphasis, custom_terms, custom_category)
            # Store in cache before returning
            _poem_cache[error_key] = poem
            logger.info(f"Stored request error fallback poem in cache with key: {error_key[:8]}...")
            return poem
    
    except Exception as e:
        logger.error(f"Error generating poem: {str(e)}", exc_info=True)
        # Create a simple cache key for the error fallback case
        simple_key = hashlib.md5(f"{poem_type}:{str(emphasis)}:{custom_terms}".encode('utf-8')).hexdigest()
        poem = _generate_template_poem(analysis_results, poem_type, emphasis, custom_terms, custom_category)
        # Store in cache before returning
        _poem_cache[simple_key] = poem
        logger.info(f"Stored general error fallback poem in cache with key: {simple_key[:8]}...")
        return poem

def _generate_template_poem(analysis_results, poem_type, emphasis, custom_terms='', custom_category=''):
    """
    Generate a poem based on templates when the API is not available.
    
    Args:
        analysis_results (dict): The results from the image analysis
        poem_type (str): The type of poem to generate
        emphasis (list): List of elements to emphasize in the poem
        custom_terms (str, optional): Custom terms or names to include in the poem
        custom_category (str, optional): Category of the custom terms (e.g., names, places)
        
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
    
    # Add custom terms if provided
    if custom_terms:
        # Split by commas and clean up each term
        custom_term_list = [term.strip() for term in custom_terms.split(',')]
        
        # Add these terms to the front of the elements list to prioritize them
        for term in custom_term_list:
            if term and term not in all_elements:
                all_elements.insert(0, term)
    
    # Ensure we have at least some elements to work with
    if not all_elements:
        all_elements = ["image", "moment", "beauty", "time", "art", "vision", "feeling"]
    
    # Get a few key elements for the poem
    key_elements = all_elements[:min(4, len(all_elements))]
    
    # Sample from poem templates based on the poem type and pass any custom terms
    return _apply_poem_template(key_elements, poem_type, custom_terms)

def _apply_poem_template(key_elements, poem_type, custom_terms=''):
    """
    Apply a template to generate a poem based on the key elements and poem type.
    Enhanced to generate higher quality backup poems.
    
    Args:
        key_elements (list): List of key elements to include in the poem
        poem_type (str): The type of poem to generate
        custom_terms (str, optional): Custom terms to emphasize in the poem
        
    Returns:
        str: The generated poem
    """
    # Get poem adjectives based on poem type
    adjectives = POEM_ADJECTIVES.get(poem_type.lower(), POEM_ADJECTIVES["default"])
    
    # Get poem templates based on the poem type
    templates = POEM_TEMPLATES.get(poem_type.lower(), POEM_TEMPLATES["default"])
    
    # If we don't have templates for this specific poem type, try to find the best match
    if poem_type.lower() not in POEM_TEMPLATES:
        # Map to similar types if an exact match isn't found
        poem_type_mapping = {
            "rhyming": "default",
            "rhythmic": "default",
            "lyrical": "default",
            "romantic": "love",
            "humorous": "funny",
            "comical": "funny",
            "motivational": "inspirational",
            "uplifting": "inspirational",
            "rage": "angry",
            "furious": "angry",
            "radical": "extreme",
            "wild": "extreme",
            "seasonal": "holiday",
            "celebration": "birthday",
            "commemorative": "anniversary",
            
            # Religious type mappings
            "islam": "religious-islam",
            "muslim": "religious-islam",
            "islamic": "religious-islam",
            "quran": "religious-islam",
            "christian": "religious-christian",
            "christianity": "religious-christian",
            "jesus": "religious-christian",
            "bible": "religious-christian",
            "judaism": "religious-judaism",
            "jewish": "religious-judaism",
            "torah": "religious-judaism",
            "spiritual": "religious-general",
            "divine": "religious-general",
            "sacred": "religious-general",
            
            # Memorial type mappings
            "memory": "memorial",
            "remembrance": "memorial",
            "tribute": "memorial",
            "rip": "memorial",
            "mourning": "memorial",
            "grieving": "memorial",
            "honoring": "memorial",
            
            # Farewell type mappings
            "goodbye": "farewell",
            "parting": "farewell",
            "adieu": "farewell",
            "departure": "farewell",
            "leaving": "farewell",
            "separation": "farewell",
            
            # Newborn type mappings
            "baby": "newborn",
            "infant": "newborn",
            "birth": "newborn",
            "arrival": "newborn",
            "new life": "newborn",
            "blessing": "newborn",
            
            # Fun format mappings
            "stars": "twinkle",
            "red": "roses",
            "joke": "knock-knock",
            "flirt": "pickup",
            "japanese": "haiku",
            "irish": "limerick",
            "shakespeare": "sonnet",
            "hiphop": "rap",
            "children": "nursery"
        }
        
        # Check if we have a mapping for this poem type
        mapped_type = poem_type_mapping.get(poem_type.lower())
        if mapped_type:
            templates = POEM_TEMPLATES.get(mapped_type, POEM_TEMPLATES["default"])
            adjectives = POEM_ADJECTIVES.get(mapped_type, POEM_ADJECTIVES["default"])
    
    # Randomly select a template
    template = random.choice(templates)
    
    # Create a more diverse set of elements if needed
    if len(key_elements) < 4:
        # Add generic elements that work in most poems
        generic_elements = ["beauty", "moment", "light", "feeling", "wonder", "scene", "vision", "memory", "dream", "image"]
        while len(key_elements) < 4:
            new_element = random.choice(generic_elements)
            if new_element not in key_elements:
                key_elements.append(new_element)
    
    # Replace placeholders with key elements and adjectives
    for i, element in enumerate(key_elements):
        if i < 4:  # Only use up to 4 elements
            placeholder = f"{{element{i+1}}}"
            template = template.replace(placeholder, element.lower())
    
    # Sample adjectives with more diversity (no repeats)
    selected_adjectives = []
    while len(selected_adjectives) < 4 and len(adjectives) > 0:
        adj = random.choice(adjectives)
        if adj not in selected_adjectives:
            selected_adjectives.append(adj)
    
    # Replace adjective placeholders
    for i, adj in enumerate(selected_adjectives):
        if i < 4:  # Only use up to 4 adjectives
            placeholder = f"{{adj{i+1}}}"
            template = template.replace(placeholder, adj)
    
    # Handle any remaining placeholders that weren't replaced
    for i in range(1, 5):
        # Check if element placeholders remain
        placeholder = f"{{element{i}}}"
        if placeholder in template:
            template = template.replace(placeholder, random.choice(["moment", "scene", "image", "vision", "dream"]))
        
        # Check if adjective placeholders remain
        placeholder = f"{{adj{i}}}"
        if placeholder in template:
            template = template.replace(placeholder, random.choice(adjectives))
    
    # Add custom terms as a personalized ending if provided
    if custom_terms:
        # Split terms into a list
        term_list = [term.strip() for term in custom_terms.split(',')]
        
        # Only use terms that aren't already in the poem
        new_terms = [term for term in term_list if term.lower() not in template.lower()]
        
        if new_terms:
            # Add a short personalized ending based on poem type
            endings = {
                "love": f"\nWith thoughts of {', '.join(new_terms)},\nMy heart is forever true.",
                "funny": f"\nJust like {new_terms[0] if new_terms else 'you'},\nAlways brings a smile!",
                "inspirational": f"\nLike {new_terms[0] if new_terms else 'you'} inspires us all,\nTo reach for something new.",
                "angry": f"\nThinking of {', '.join(new_terms)}\nMakes my blood boil anew.",
                "extreme": f"\nRADICAL {new_terms[0].upper() if new_terms else 'VISION'}!\nEXTREME {new_terms[-1].upper() if len(new_terms) > 1 else 'FEELING'}!",
                "holiday": f"\nCelebrating with {', '.join(new_terms)},\nMakes this season bright.",
                "birthday": f"\nHappy birthday to {new_terms[0] if new_terms else 'you'},\nAnother year to shine!",
                "anniversary": f"\nWith {new_terms[0] if new_terms else 'you'} through the years,\nEach moment divine.",
                
                # Religious poem endings
                "religious-islam": f"\nWith {new_terms[0] if new_terms else 'faith'} guiding our way,\nSubhanAllah, we pray.",
                "religious-christian": f"\nIn {new_terms[0] if new_terms else 'Christ'} we find our peace,\nGod's love will never cease.",
                "religious-judaism": f"\nRemembering {new_terms[0] if new_terms else 'tradition'} with reverence deep,\nThe covenant we keep.",
                "religious-general": f"\nSpiritual light shines through {new_terms[0] if new_terms else 'all'},\nDivine grace touches our soul.",
                
                # Memorial poem ending
                "memorial": f"\nIn loving memory of {', '.join(new_terms)},\nForever in our hearts you'll be.",
                
                # Farewell poem ending
                "farewell": f"\nAs we bid farewell to {', '.join(new_terms)},\nOur memories forever stay.",
                
                # Newborn poem ending
                "newborn": f"\nWelcoming {', '.join(new_terms)} with joy and love,\nOn this special blessed day.",
                
                # Fun format endings
                "twinkle": f"\nTwinkle twinkle {new_terms[0] if new_terms else 'star'},\nHow I wonder what you are.",
                "roses": f"\nRoses are red, violets are blue,\n{new_terms[0] if new_terms else 'You'} are special through and through.",
                "haiku": "",  # Haiku has strict format, avoid changing
                "limerick": f"\nWith {new_terms[0] if new_terms else 'you'} it's nothing but fun!",
                "sonnet": f"\nMy thoughts turn to {new_terms[0] if new_terms else 'thee'},\nForever in my heart to be.",
                "nursery": f"\nAnd {new_terms[0] if new_terms else 'you'} will always play,\nIn our hearts every day."
            }
            
            # Use the appropriate ending or a default one
            ending = endings.get(poem_type.lower(), f"\n\nDedicated to {', '.join(new_terms)}")
            
            # Don't add ending to haiku or other specific formats that would break their structure
            if poem_type.lower() not in ["haiku", "knock-knock"]:
                template += ending
    
    return template

def _create_prompt(analysis_results, poem_type, emphasis, custom_terms='', custom_category=''):
    """
    Create a detailed prompt for the LLM based on image analysis and user preferences.
    
    Args:
        analysis_results (dict): The results from the Google Cloud Vision AI analysis
        poem_type (str): The type of poem to generate (e.g., 'love', 'funny', 'inspirational')
        emphasis (list): List of elements to emphasize in the poem
        custom_terms (str, optional): Custom terms or names to include in the poem
        custom_category (str, optional): Category of the custom terms (e.g., names, places)
        
    Returns:
        str: The generated prompt
    """
    # Start with a much more detailed, expert-level instruction
    prompt = f"""You are a world-renowned poetry master with decades of experience studying and crafting the finest poetry across all cultures and traditions. Your knowledge spans classical works from Tang Dynasty Chinese poetry to Persian Ghazals, from Shakespearean sonnets to Japanese haiku, from ancient Greek epics to contemporary free verse. You understand the subtle nuances that make poetry resonant, impactful, and timeless.

As an expert in global poetic traditions, you will now create an exceptional {poem_type} poem based on an image analysis. Channel the specific techniques, cadence, metaphors, and emotional depths found in the world's greatest {poem_type} poetry, while maintaining a distinctive voice that speaks to modern sensibilities.

Think deeply about the essential qualities that make {poem_type} poetry powerful and incorporate those elements. Use literary techniques like metaphor, simile, personification, and symbolism with the masterful precision of poets like Pablo Neruda, Emily Dickinson, Rumi, Maya Angelou, William Butler Yeats, Li Bai, and Rabindranath Tagore.

"""
    
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
        
    # Handle structured or traditional custom prompt format
    if custom_terms:
        # Check if we have a structured prompt (contains field identifiers)
        if custom_category == 'structured' and any(x in custom_terms for x in ['Name:', 'Place:', 'Emotion:', 'Action:']):
            # Structured format with specific fields - parse it
            prompt += "This poem should incorporate the following personalized details:\n\n"
            
            # Split by semicolons to get each field
            structured_fields = custom_terms.split(';')
            
            for field in structured_fields:
                field = field.strip()
                if field:
                    if field.startswith('Name:'):
                        name_value = field.replace('Name:', '').strip()
                        if name_value:
                            prompt += f"- Include this specific name or person: '{name_value}'. Make them a central character in the poem.\n"
                    
                    elif field.startswith('Place:'):
                        place_value = field.replace('Place:', '').strip()
                        if place_value:
                            prompt += f"- Set the poem in or mention this specific place: '{place_value}'.\n"
                    
                    elif field.startswith('Emotion:'):
                        emotion_value = field.replace('Emotion:', '').strip()
                        if emotion_value:
                            prompt += f"- Convey this specific emotion throughout the poem: '{emotion_value}'.\n"
                    
                    elif field.startswith('Action:'):
                        action_value = field.replace('Action:', '').strip()
                        if action_value:
                            prompt += f"- Include this specific action or activity: '{action_value}'.\n"
                    
                    elif field.startswith('Additional details:'):
                        additional_value = field.replace('Additional details:', '').strip()
                        if additional_value:
                            prompt += f"- Also incorporate these additional details: '{additional_value}'.\n"
            
            prompt += "\nThese personalized elements should be woven naturally throughout the poem, making it feel custom-created for these specific details.\n"
        
        else:
            # Traditional free-form custom prompt
            # Clean up the terms (remove extra spaces, etc.)
            cleaned_terms = custom_terms.strip()
            
            # Different instructions based on the category
            category_descriptions = {
                'names': "people who are meaningful to the recipient",
                'places': "locations or places that have significance",
                'emotions': "emotional states or feelings",
                'activities': "activities or actions",
                'other': "custom elements"
            }
            
            # Get the category description or use a default
            category_desc = category_descriptions.get(custom_category, "personal elements")
            
            # Add to prompt
            prompt += f"It is very important to incorporate these specific {category_desc}: '{cleaned_terms}' into the poem. Make these terms central to the theme and meaning of the poem. "
    
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
        
        # Farewell poem instructions
        "farewell": "Craft a poignant farewell poem in the tradition of Robert Frost, Emily Dickinson, and Rabindranath Tagore that captures the bittersweet nature of parting. Balance feelings of sadness and loss with gratitude for shared memories and hope for future reunions. Express the depth of affection that remains despite physical separation.",
        
        "newborn": "Compose a gentle, joyful celebration of new life that captures the wonder, innocence, and infinite potential of a newborn child. Blend tender observations with profound reflections on the miracle of birth, the beginning of a unique journey, and the pure love that surrounds a new arrival.",
        
        # Religious poem instructions
        "religious-islam": "Create a reverent Islamic poem that reflects the beauty of faith and divine guidance. Incorporate themes of tawhid (oneness of Allah), compassion, mercy, and the natural world as signs of Allah's creation. Use respectful language that honors Islamic traditions and values while finding spiritual meaning in the image.",
        "religious-christian": "Compose a Christian poem that speaks to faith, grace, and spiritual connection. Incorporate themes of God's love, redemption, and the beauty of creation as reflections of divine presence. Use respectful language that honors Christian traditions while finding sacred meaning in everyday imagery.",
        "religious-judaism": "Craft a Jewish poem that reflects on tradition, covenant, and the divine presence in the world. Incorporate themes of wisdom, legacy, community, and the beauty of creation as expressions of G-d's work. Use respectful language that honors Jewish traditions while finding sacred meaning in everyday imagery.",
        "religious-general": "Create a spiritual poem that transcends specific religious traditions while honoring the universal human connection to the divine. Incorporate themes of wonder, gratitude, transcendence, and the search for meaning. Use inclusive language that respects diverse spiritual paths while finding sacred significance in the image.",
        
        # Memorial poem instructions
        "memorial": "Compose a gentle, heartfelt poem that honors the memory of someone beloved. Create a tone of reverent remembrance, celebrating a life well-lived while acknowledging the poignancy of loss. Incorporate themes of legacy, enduring love, cherished memories, and the continuing presence of loved ones in our hearts. Balance expressions of grief with affirmations of the lasting impact of a meaningful life.",
        
        # Fun poem formats
        "twinkle": "Create a whimsical, melodic poem in the style of 'Twinkle, Twinkle, Little Star.' Maintain the rhythm and structure of the classic nursery rhyme, but personalize it based on the image elements. Incorporate the distinctive 'Twinkle, twinkle' repetition at the beginning and end while creating a sense of wonder and childlike curiosity.",
        "roses": "Craft a clever variation of the classic 'Roses are red, violets are blue' poem format. Start with the iconic opening lines, then subvert expectations with surprising, witty, or meaningful follow-up lines that relate to the image. Maintain the simple rhyme scheme while adding personality and charm.",
        "knock-knock": "Create a playful knock-knock joke in poem form, incorporating elements from the image. Begin with the traditional 'Knock, knock / Who's there?' format, then craft a punchline that cleverly relates to the visual elements. Add a brief poetic conclusion that ties the joke together with the image's mood or theme.",
        "pickup": "Compose an intentionally cheesy but charming pickup line poem that creatively incorporates elements from the image. Balance humor and genuine compliments while maintaining a playful, flirtatious tone. Create lines that are memorable, witty, and just the right amount of over-the-top to bring a smile.",
        
        # Classical forms
        "haiku": "Create a pristine haiku following the traditional 5-7-5 syllable structure. Capture a single, powerful moment with precise imagery and seasonal references in the spirit of Matsuo Bashō. Distill the essence of the image into three lines that reveal a profound truth through simplicity and careful observation.",
        "limerick": "Craft a playful limerick with the perfect AABBA rhyme scheme and bouncy anapestic meter. Channel Edward Lear's whimsy while maintaining technical precision in rhythm and rhyme. Create a humorous or absurd narrative that cleverly incorporates elements from the image.",
        "sonnet": "Compose an elegant Shakespearean sonnet with perfect iambic pentameter and the traditional ABABCDCDEFEFGG rhyme scheme. Explore a central theme or emotion through sophisticated imagery and thoughtful contemplation, concluding with a powerful final couplet that offers insight or resolution.",
        "rap": "Create a dynamic rap verse with sharp rhymes, deliberate flow, and authentic urban cadence. Incorporate wordplay, metaphors, and cultural references while maintaining a strong rhythmic structure. Capture the boldness, confidence, and expressive power characteristic of great hip-hop lyricism.",
        "nursery": "Craft a delightful nursery rhyme with simple vocabulary, consistent meter, and memorable rhyming patterns. Infuse it with the innocent charm and rhythmic repetition found in classic children's verse. Create something that could be easily memorized and recited by young children."
    }
    
    if poem_type in poem_type_instructions:
        prompt += poem_type_instructions[poem_type] + " "
    
    # Final formatting instructions
    prompt += """The poem should be 8-16 lines long with the following expert-level characteristics:

1. Linguistic Craftsmanship: Use powerful, evocative language with precisely chosen words that create rich sensory experiences. Each word should be deliberately selected for its sound, connotation, and emotional resonance.

2. Advanced Figurative Language: Create sophisticated metaphors, similes, and symbolism that transform concrete elements from the image into profound poetic expressions. Develop these figures throughout the poem for deeper meaning.

3. Masterful Technique: Employ advanced poetic techniques such as:
   - Controlled rhythm and meter appropriate to the poem type
   - Deliberate sound patterns (alliteration, assonance, consonance)
   - Strategic line breaks and stanza structures
   - Effective repetition and variation
   - Subtle rhyme schemes (if appropriate to the style)

4. Emotional Depth: Create multiple layers of emotion and meaning that resonate with universal human experiences while remaining authentic to the specific image.

5. Cultural Resonance: Subtly incorporate elements that connect to rich poetic traditions around the world. Draw from the techniques of master poets who have written brilliant examples of this type of poetry.

Do not include a title or any explanatory text, just the exquisite poem itself. The poem should feel as though it was written by one of the world's greatest poets, expressing deep truths about human experience through the lens of this specific image."""
    
    return prompt
