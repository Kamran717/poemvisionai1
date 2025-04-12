import os
import logging

# Set up logging for easier debugging
logging.basicConfig(level=logging.DEBUG)

from app import app  # noqa: F401
from models import db  # noqa: F401

# Import membership utilities
from utils.membership import create_default_plans

if __name__ == "__main__":
    # Create all database tables if they don't exist
    with app.app_context():
        db.create_all()
        
        # Create default membership plans
        create_default_plans()
        logging.info("Database tables created successfully")
        
    app.run(host="0.0.0.0", port=5000, debug=True)
