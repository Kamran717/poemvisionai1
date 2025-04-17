import os
import logging
from flask import Flask

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Import app and db
from app import app
from models import db

# Import membership utilities
from utils.membership import create_default_plans, create_default_poem_lengths

def initialize_database():
    """Initialize database tables and default data"""
    with app.app_context():
        try:
            logger.info("Initializing database...")
            db.create_all()

            # Create default membership plans
            create_default_plans()
            create_default_poem_lengths()

            # Verify creation
            from models import Membership
            plan_count = Membership.query.count()
            logger.info(f"Database initialized with {plan_count} membership plans")

        except Exception as e:
            logger.error(f"Database initialization failed: {str(e)}", exc_info=True)
            raise

# Modern Flask initialization approach
with app.app_context():
    initialize_database()

# CLI command for manual initialization
@app.cli.command("init-db")
def init_db():
    """Initialize the database."""
    initialize_database()
    print("Database initialized")

if __name__ == "__main__":
    # Run the app
    app.run(host="0.0.0.0", port=5000, debug=True)