from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

# Initialize SQLAlchemy
db = SQLAlchemy()

class Creation(db.Model):
    """Model for storing user poem creations."""
    id = db.Column(db.Integer, primary_key=True)
    
    # Store the original image data (encoded as base64)
    image_data = db.Column(db.Text, nullable=False)
    
    # Store the analysis results from Google Vision API
    analysis_results = db.Column(db.JSON, nullable=True)
    
    # Store the generated poem
    poem_text = db.Column(db.Text, nullable=True)
    
    # Store the frame style used
    frame_style = db.Column(db.String(50), nullable=True)
    
    # Store the final creation image data (encoded as base64)
    final_image_data = db.Column(db.Text, nullable=True)
    
    # Store poem preferences
    poem_type = db.Column(db.String(50), nullable=True)
    emphasis = db.Column(db.JSON, nullable=True)  # Store as JSON array
    
    # Store creation timestamp
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Store a unique share code for public sharing
    share_code = db.Column(db.String(50), unique=True, nullable=True)
    
    def __repr__(self):
        return f'<Creation {self.id}, created at {self.created_at}>'