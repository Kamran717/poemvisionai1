from datetime import datetime
import string
import random
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

# Initialize SQLAlchemy
db = SQLAlchemy()

class User(db.Model):
    """Model for storing user information and membership status."""
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Membership fields
    is_premium = db.Column(db.Boolean, default=False)
    membership_start = db.Column(db.DateTime, nullable=True)
    membership_end = db.Column(db.DateTime, nullable=True)
    
    # Relationship with creations
    creations = db.relationship('Creation', backref='user', lazy=True)
    
    def __repr__(self):
        return f'<User {self.username}>'
    
    def set_password(self, password):
        """Set the password hash for the user."""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Check if the provided password matches the hash."""
        return check_password_hash(self.password_hash, password)

class Membership(db.Model):
    """Model for storing membership plan details."""
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)  # e.g., 'Free', 'Premium'
    price = db.Column(db.Float, nullable=False)      # Monthly price
    description = db.Column(db.Text, nullable=True)  # Plan description
    features = db.Column(db.JSON, nullable=True)     # List of features as JSON
    max_poem_types = db.Column(db.Integer, nullable=False)  # Number of poem types allowed
    max_frame_types = db.Column(db.Integer, nullable=False)  # Number of frame types allowed
    max_saved_poems = db.Column(db.Integer, nullable=False)  # Number of poems that can be saved
    has_gallery = db.Column(db.Boolean, default=False)  # Whether user has access to gallery
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Membership {self.name}>'

class Creation(db.Model):
    """Model for storing user poem creations."""
    id = db.Column(db.Integer, primary_key=True)
    
    # User relationship (can be null for anonymous users)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=True)
    
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
    
    def generate_share_code(self):
        """Generate a unique share code for this creation."""
        if not self.share_code:
            # Generate a random 10-character code
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))
            self.share_code = code
            return code
        return self.share_code

class Transaction(db.Model):
    """Model for storing payment transactions."""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), nullable=False)  # 'completed', 'pending', 'failed'
    payment_method = db.Column(db.String(50), nullable=True)
    transaction_id = db.Column(db.String(100), nullable=True)  # External payment processor ID
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationship with user
    user = db.relationship('User', backref='transactions')
    
    def __repr__(self):
        return f'<Transaction {self.id}>'