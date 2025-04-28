"""
Membership management utilities for Poem Vision AI.
"""
import logging
from datetime import datetime, timedelta
from models import db, User, Membership, Transaction, PoemLength

# Set up logging
logger = logging.getLogger(__name__)


def create_default_plans():
    """Create the default membership plans if they don't exist."""
    try:
        # Check if plans already exist
        if Membership.query.count() > 0:
            logger.info("Membership plans already exist, skipping creation.")
            return

        # Create free plan
        free_plan = Membership()
        free_plan.name = "Free"
        free_plan.price = 0.0
        free_plan.description = "Basic access to Poem Vision AI"
        free_plan.features = [
            "Generate basic poems from uploaded images",
            "Access to 3 default poem styles",
            "Limited frame designs"
        ]
        free_plan.max_poem_types = 3
        free_plan.max_frame_types = 3
        free_plan.max_saved_poems = 5
        free_plan.has_gallery = False

        # Create premium plan
        premium_plan = Membership()
        premium_plan.name = "Premium"
        premium_plan.price = 5.0
        premium_plan.description = "Full access to Poem Vision AI features"
        premium_plan.features = [
            "Access to all poem categories",
            "Personal gallery storage", 
            "Smarter AI customization",
            "Exclusive early access to new features"
        ]
        premium_plan.max_poem_types = 100  
        premium_plan.max_frame_types = 100  
        premium_plan.max_saved_poems = 500  
        premium_plan.has_gallery = True

        # Add plans to database
        db.session.add(free_plan)
        db.session.add(premium_plan)
        db.session.commit()

        logger.info("Default membership plans created successfully.")
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating default membership plans: {str(e)}")


def get_user_plan(user_id):
    """Get the membership plan for a user."""
    try:
        user = User.query.get(user_id)
        if not user:
            return None

        if user.is_premium:
            return Membership.query.filter_by(name="Premium").first()
        else:
            return Membership.query.filter_by(name="Free").first()
    except Exception as e:
        logger.error(f"Error getting user plan: {str(e)}")
        return None


def check_poem_type_access(user_id, poem_type):
    """Check if a user has access to a specific poem type."""
    # List of free poem types
    FREE_POEM_TYPES = ['default', 'love', 'funny']

    # If the poem type is in the free list, anyone can access it
    if poem_type in FREE_POEM_TYPES:
        return True

    # If no user_id (anonymous user), only allow free poem types
    if not user_id:
        return False

    # Check if the user is premium
    user = User.query.get(user_id)
    if not user:
        return False

    return user.is_premium


def check_frame_access(user_id, frame_style):
    """Check if a user has access to a specific frame style."""
    # List of free frame styles
    FREE_FRAME_STYLES = ['classic', 'minimalist', 'none']

    # If the frame style is in the free list, anyone can access it
    if frame_style in FREE_FRAME_STYLES:
        return True

    # If no user_id (anonymous user), only allow free frame styles
    if not user_id:
        return False

    # Check if the user is premium
    user = User.query.get(user_id)
    if not user:
        return False

    return user.is_premium


def process_payment(user_id, payment_method, transaction_id):
    """Process a premium membership payment."""
    try:
        user = User.query.get(user_id)
        if not user:
            return {"success": False, "message": "User not found"}

        # Create a new transaction record
        transaction = Transaction()
        transaction.user_id = user_id
        transaction.amount = 5.0  
        transaction.status = "completed"
        transaction.payment_method = payment_method
        transaction.transaction_id = transaction_id

        # Update user membership status
        user.is_premium = True
        user.membership_start = datetime.utcnow()
        user.membership_end = datetime.utcnow() + timedelta(days=30)  

        # Save to database
        db.session.add(transaction)
        db.session.commit()

        return {"success": True, "message": "Payment processed successfully"}
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error processing payment: {str(e)}")
        return {
            "success": False,
            "message": f"Error processing payment: {str(e)}"
        }


def cancel_membership(user_id):
    """Cancel a user's premium membership."""
    try:
        user = User.query.get(user_id)
        if not user:
            return {"success": False, "message": "User not found"}

        # User will remain premium until the end of their current period
        # They will just not auto-renew
        # We're not actually changing status here, just recording the cancellation

        return {
            "success": True,
            "message":
            "Membership will not renew at the end of the current period"
        }
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error canceling membership: {str(e)}")
        return {
            "success": False,
            "message": f"Error canceling membership: {str(e)}"
        }


def get_user_creations(user_id, limit=10):
    """Get a list of creations for a specific user."""
    from models import Creation

    try:
        creations = Creation.query.filter_by(user_id=user_id).order_by(
            Creation.created_at.desc()).limit(limit).all()
        return creations
    except Exception as e:
        logger.error(f"Error getting user creations: {str(e)}")
        return []


def get_available_poem_types(user_id):
    """Get the list of poem types available to a user based on their plan."""
    # All poem types in the system
    ALL_POEM_TYPES = [
        # Standard poems
        {
            "id": "general verse",
            "name": "General Verse",
            "free": True
        },
        {
            "id": "love",
            "name": "Romantic/Love Poem",
            "free": True
        },
        {
            "id": "funny",
            "name": "Funny/Humorous",
            "free": True
        },
        {
            "id": "inspirational",
            "name": "Inspirational/Motivational",
            "free": True
        },
        {
            "id": "angry",
            "name": "Angry/Intense",
            "free": False
        },
        {
            "id": "extreme",
            "name": "Extreme/Bold",
            "free": False
        },
        {
            "id": "holiday",
            "name": "Holiday",
            "free": False
        },
        {
            "id": "birthday",
            "name": "Birthday",
            "free": False
        },
        {
            "id": "anniversary",
            "name": "Anniversary",
            "free": False
        },
        {
            "id": "nature",
            "name": "Nature",
            "free": False
        },
        {
            "id": "friendship",
            "name": "Friendship",
            "free": False
        },

        # Life events
        {
            "id": "memorial",
            "name": "In Memory/RIP",
            "free": False
        },
        {
            "id": "farewell",
            "name": "Farewell/Goodbye",
            "free": False
        },
        {
            "id": "newborn",
            "name": "Newborn/Baby",
            "free": False
        },

        # Religious
        {
            "id": "religious-islam",
            "name": "Islamic/Muslim",
            "free": False
        },
        {
            "id": "religious-christian",
            "name": "Christian",
            "free": False
        },
        {
            "id": "religious-judaism",
            "name": "Jewish/Judaism",
            "free": False
        },
        {
            "id": "religious-general",
            "name": "Spiritual/General",
            "free": False
        },
        {
            "id": "william-shakespeare",
            "name": "William Shakespeare",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "emily-dickinson",
            "name": "Emily Dickinson",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "dante-alighieri",
            "name": "Dante Alighieri",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "maya-angelou",
            "name": "Maya Angelou",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "robert-frost",
            "name": "Robert Frost",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "rumi",
            "name": "Rumi",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "langston-hughes",
            "name": "Langston Hughes",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "sylvia-plath",
            "name": "Sylvia Plath",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "pablo-neruda",
            "name": "Pablo Neruda",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "walt-whitman",
            "name": "Walt Whitman",
            "category": "famousPoets",
            "free": False
        },
        {
            "id": "edgar-allan-poe",
            "name": "Edgar Allan Poe",
            "category": "famousPoets",
            "free": False
        },

        #Flirty fun
        {
            "id": "pick-up",
            "name": "Pick-Up Lines",
            "free": False
        },
        {
            "id": "roast-you",
            "name": "Roast You",
            "free": False
        },
        {
            "id": "first-date-feel",
            "name": "First Date Feel",
            "free": False
        },
        {
            "id": "love-at-first-sight",
            "name": "Love at First Sight",
            "free": False
        },

        # Congratulations Category
        {
            "id": "graduation",
            "name": "Graduation",
            "category": "congratulations",
            "free": False
        },
        {
            "id": "new-job",
            "name": "New Job",
            "free": False
        },
        {
            "id": "wedding",
            "name": "Wedding",
            "free": False
        },
        {
            "id": "engagement",
            "name": "Engagement",
            "free": False
        },
        {
            "id": "new-baby",
            "name": "New Baby",
            "free": False
        },
        {
            "id": "promotion",
            "name": "Promotion",
            "free": False
        },
        {
            "id": "new-home",
            "name": "New Home",
            "free": False
        },
        {
            "id": "new-car",
            "name": "New Car",
            "free": False
        },
        {
            "id": "new-pet",
            "name": "New Pet",
            "free": False
        },
        {
            "id": "first-day-of-school",
            "name": "First Day of School",
            "free": False
        },
        {
            "id": "retirement",
            "name": "Retirement",
            "free": False
        },

        #Holidays
        {
            "id": "new-year",
            "name": "New Year",
            "free": False
        },
        {
            "id": "valentines-day",
            "name": "Valentines Day",
            "free": False
        },
        {
            "id": "ramadan",
            "name": "Ramadan",
            "free": False
        },
        {
            "id": "halloween",
            "name": "Halloween",
            "free": False
        },
        {
            "id": "easter",
            "name": "Easter",
            "free": False
        },
        {
            "id": "thanksgiving",
            "name": "Thanksgiving",
            "free": False
        },
        {
            "id": "mother-day",
            "name": "Mother Day",
            "free": False
        },
        {
            "id": "father-day",
            "name": "Father Day",
            "free": False
        },
        {
            "id": "christmas",
            "name": "Christmas",
            "free": False
        },
        {
            "id": "independence-day",
            "name": "Independence Day",
            "free": False
        },
        {
            "id": "hanukkah",
            "name": "Hanukkah",
            "free": False
        },
        {
            "id": "diwali",
            "name": "Diwali",
            "free": False
        },
        {
            "id": "new-year-eve",
            "name": "New Year Eve",
            "free": False
        },

        # Fun formats
        {
            "id": "twinkle",
            "name": "Twinkle Twinkle",
            "free": False
        },
        {
            "id": "roses",
            "name": "Roses are Red",
            "free": False
        },
        {
            "id": "knock-knock",
            "name": "Knock Knock",
            "free": False
        },
        {
            "id": "hickory dickory dock",
            "name": "Hickory Dickory Dock",
            "free": False
        },
        {
            "id": "nursery-rhymes",
            "name": "Nursery Rhymes",
            "free": False
        },

        # Music
        {
            "id": "rap/hiphop",
            "name": "Rap/Hip-Hop",
            "free": False
        },
        {
            "id":"country",
            "name": "Country",
            "free": False
        },
        {
            "id": "rock",
            "name": "Rock",
            "free": False
        },
        {
            "id": "jazz",
            "name": "Jazz",
            "free": False
        },
        {
            "id": "pop",
            "name": "Pop",
            "free": False
        },

        #Artist
        {
            "id": "eminem",
            "name": "Eminem",
            "free": False
        },
        {
            "id": "kendrick-lamar",
            "name": "Kendrick Lamar",
            "free": False
        },
        {
            "id": "taylor-swift",
            "name": "Taylor Swift",
            "free": False
        },
        {
            "id": "drake",
            "name": "Drake",
            "free": False
        },
        {
            "id": "50cent",
            "name": "50 Cent",
            "free": False
        },
        {
            "id": "lil-wayne",
            "name": "Lil Wayne",
            "free": False
        },
        {
            "id": "doja-cat",
            "name": "Doja Cat",
            "free": False
        },
        {
            "id": "nicki-minaj",
            "name": "Nicki Minaj",
            "free": False
        },
        {
            "id": "j. cole",
            "name": "J. Cole",
            "free": False
        },
        {
            "id": "elvis-presley",
            "name": "Elvis Presley",
            "free": False
        },
        {
            "id": "tupac",
            "name": "Tupac Shakur",
            "free": False
        },
        {
            "id": "biggie-smalls",
            "name": "Biggie Smalls",
            "free": False
        },
        {
            "id": "buddy-holly",
            "name": "Buddy Holly",
            "free": False
        },
        {
            "id": "luis-armstrong",
            "name": "Luis Armstrong",
            "free": False
        },


        # Classical forms
        {
            "id": "haiku",
            "name": "Haiku",
            "free": False
        },
        {
            "id": "limerick",
            "name": "Limerick",
            "free": False
        },
        {
            "id": "tanka",
            "name": "Tanka",
            "free": False
        },
        {
            "id": "senryu",
            "name": "Senryu",
            "free": False
        },

        # Tribulations
        {
            "id": "memorial",
            "name": "In Memory/RIP",
            "free": False
        },
        {
            "id": "farewell",
            "name": "Farewell/Goodbye",
            "free": False
        },
        {
            "id": "get-well-soon",
            "name": "Get Well Soon",
            "free": False
        },
        {
            "id": "apology",
            "name": "Apology/Sorry",
            "free": False
        },
        {
            "id": "divorce",
            "name": "Divorce/Breakup",
            "free": False
        },
        {
            "id": "hard-times",
            "name": "Hard Times/Struggles",
            "free": False
        },
        {
            "id": "missing-you",
            "name": "Missing You",
            "free": False
        },
        {
            "id": "conflict",
            "name": "Conflict/Disagreement",
            "free": False
        },
        {
            "id": "lost-pet",
            "name": "Lost Pet",
            "free": False
        }
    ]

    # Check if user is premium
    user = User.query.get(user_id) if user_id else None
    is_premium = user and user.is_premium

    # Return all poem types with their availability status
    # We're not filtering anymore - we want to show all options
    return ALL_POEM_TYPES


def get_available_frames(user_id):
    """Get the list of frames available to a user based on their plan."""
    # All frame styles in the system
    ALL_FRAMES = [
        {
            "id": "classic",
            "name": "Classic",
            "free": True
        },
        {
            "id": "minimalist",
            "name": "Minimalist",
            "free": True
        },
        {
            "id": "none",
            "name": "No Frame",
            "free": True
        },
        {
            "id": "elegant",
            "name": "Elegant",
            "free": False
        },
        {
            "id": "vintage",
            "name": "Vintage",
            "free": False
        },
        {
            "id": "ornate",
            "name": "Ornate",
            "free": False
        },
        {
            "id": "modern",
            "name": "Modern",
            "free": False
        },
        {
            "id": "polaroid",
            "name": "Polaroid",
            "free": False
        },
        {
            "id": "shadow",
            "name": "Shadow Box",
            "free": False
        },
        {
            "id": "ornate-gold",
            "name": "Ornate Gold",
            "free": False
        },
        {
            "id": "ornate-brown",
            "name": "Ornate Brown",
            "free": False
        },
        {
            "id": "futuristic",
            "name": "Futuristic",
            "free": False
        },
        {
            "id": "era",
            "name": "Era",
            "free": False
        },
        {
            "id": "red",
            "name": "Red",
            "free": False
        },
        {
            "id": "blue",
            "name": "Blue",
            "free": False
        },
        {
            "id": "light blue",
            "name": "Light Blue",
            "free": False
        },
        {
            "id": "ornate-green",
            "name": "Ornate Green",
            "free": False
        },
        {
            "id": "orange",
            "name": "Orange",
            "free": False
        },
        {
            "id": "purple",
            "name": "Purple",
            "free": False
        }
    ]

    # Check if user is premium
    user = User.query.get(user_id) if user_id else None
    is_premium = user and user.is_premium

    # Return all frames with their availability status
    # We're not filtering anymore - we want to show all options
    return ALL_FRAMES

def create_default_poem_lengths():
    """Create default poem length options"""
    try:
        if PoemLength.query.count() > 0:
            return

        lengths = [
            {"name": "short", "display_name": "Short (4-6 lines)", "line_range": "4-6", "is_premium": False},
            {"name": "medium", "display_name": "Medium (8-12 lines)", "line_range": "8-12", "is_premium": True},
            {"name": "long", "display_name": "Long (14-20 lines)", "line_range": "14-20", "is_premium": True}
        ]

        for length in lengths:
            db.session.add(PoemLength(**length))

        db.session.commit()
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error creating poem lengths: {str(e)}")

def get_available_poem_lengths(user_id):
    """Get available poem lengths based on user's membership"""
    user = User.query.get(user_id) if user_id else None
    is_premium = user and user.is_premium

    lengths = PoemLength.query.order_by(PoemLength.order).all()

    return [{
        "id": length.name,
        "name": length.display_name,
        "free": not length.is_premium,
        "has_access": not length.is_premium or is_premium
    } for length in lengths]

def check_poem_length_access(user_id, length_name):
    """Check if user has access to a specific poem length"""
    length = PoemLength.query.filter_by(name=length_name).first()
    if not length:
        return False

    if not length.is_premium:
        return True

    user = User.query.get(user_id) if user_id else None
    return user and user.is_premium
