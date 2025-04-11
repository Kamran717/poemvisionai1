import os
import logging

# Set up logging for easier debugging
logging.basicConfig(level=logging.DEBUG)

from app import app  # noqa: F401
from models import db  # noqa: F401

if __name__ == "__main__":
    # Create all database tables if they don't exist
    with app.app_context():
        db.create_all()
        
    app.run(host="0.0.0.0", port=5000, debug=True)
