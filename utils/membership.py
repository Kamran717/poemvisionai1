"""
Membership management utilities for Poem Vision AI.
"""
import logging
from datetime import datetime, timedelta
from models import db, User, Membership, Transaction

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
        free_plan = Membership(name="Free",
                               price=0.0,
                               description="Basic access to Poem Vision AI",
                               features=[
                                   "Generate basic poems from uploaded images",
                                   "Access to 3 default poem styles",
                                   "Limited frame designs"
                               ],
                               max_poem_types=3,
                               max_frame_types=3,
                               max_saved_poems=5,
                               has_gallery=False)

        # Create premium plan
        premium_plan = Membership(
            name="Premium",
            price=5.0,
            description="Full access to Poem Vision AI features",
            features=[
                "Access to all poem categories",
                "Unlock all creative frame designs",
                "Personal gallery storage", "Smarter AI customization",
                "Exclusive early access to new features"
            ],
            max_poem_types=100,  # effectively unlimited
            max_frame_types=100,  # effectively unlimited
            max_saved_poems=500,  # effectively unlimited
            has_gallery=True)

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
        transaction = Transaction(
            user_id=user_id,
            amount=5.0,  # $5/month premium plan
            status="completed",
            payment_method=payment_method,
            transaction_id=transaction_id)

        # Update user membership status
        user.is_premium = True
        user.membership_start = datetime.utcnow()
        user.membership_end = datetime.utcnow() + timedelta(
            days=30)  # 30-day membership

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
            "id": "free verse",
            "name": "Free Verse",
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
            "category": "congratulations",
            "free": False
        },
        {
            "id": "wedding",
            "name": "Wedding",
            "category": "congratulations",
            "free": False
        },
        {
            "id": "new-baby",
            "name": "New Baby",
            "category": "congratulations",
            "free": False
        },
        {
            "id": "promotion",
            "name": "Promotion",
            "category": "congratulations",
            "free": False
        },
        {
            "id": "new-home",
            "name": "New Home",
            "category": "congratulations",
            "free": False
        },
        {
            "id": "new-car",
            "name": "New Car",
            "category": "congratulations",
            "free": False
        },
        {
            "id": "new-pet",
            "name": "New Pet",
            "category": "congratulations",
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
            "id": "pickup",
            "name": "Pick-up Lines",
            "free": False
        },
        {
            "id": "hickory dickory dock",
            "name": "Hickory Dickory Dock",
            "free": False
        },

        # mirror
        {
            "id": "mirror",
            "name": "Mirror",
            "free": False
        },
        {
            "id": "fairytale",
            "name": "Fairytale",
            "free": False
        },
        {
            "id": "mysterious",
            "name": "Mysterious",
            "free": False
        },
        {
            "id": "whimsical",
            "name": "Whimsical",
            "free": False
        },
        {
            "id": "haunted",
            "name": "Haunted",
            "free": False
        },
        {
            "id": "mystical",
            "name": "Mystical",
            "free": False
        },
        {
            "id": "romantic",
            "name": "Romantic",
            "free": False
        },
        {
            "id": "magical",
            "name": "Magical",
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
            "id": "sonnet",
            "name": "Sonnet",
            "free": False
        },
        {
            "id": "rap",
            "name": "Rap/Hip-Hop",
            "free": False
        },
        {
            "id": "nursery",
            "name": "Nursery Rhyme",
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
    ALL_FRAMES = [{
        "id": "classic",
        "name": "Classic",
        "free": True
    }, {
        "id": "minimalist",
        "name": "Minimalist",
        "free": True
    }, {
        "id": "none",
        "name": "No Frame",
        "free": True
    }, {
        "id": "elegant",
        "name": "Elegant",
        "free": False
    }, {
        "id": "vintage",
        "name": "Vintage",
        "free": False
    }, {
        "id": "ornate",
        "name": "Ornate",
        "free": False
    }, {
        "id": "modern",
        "name": "Modern",
        "free": False
    }, {
        "id": "polaroid",
        "name": "Polaroid",
        "free": False
    }, {
        "id": "shadow",
        "name": "Shadow Box",
        "free": False
    }]

    # Check if user is premium
    user = User.query.get(user_id) if user_id else None
    is_premium = user and user.is_premium

    # Return all frames with their availability status
    # We're not filtering anymore - we want to show all options
    return ALL_FRAMES
