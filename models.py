from datetime import datetime, timedelta
import secrets
import jwt
import time
import string
import random
from flask_sqlalchemy import SQLAlchemy
from flask import current_app
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
    stripe_customer_id = db.Column(db.String(255), unique=True, nullable=True)
    subscription_id = db.Column(db.String(255), unique=True, nullable=True)
    is_cancelled = db.Column(db.Boolean, default=False)
    cancellation_feedback = db.Column(db.Text)
    is_email_verified = db.Column(db.Boolean, default=False)
    email_verification_token = db.Column(db.String(64), nullable=True)
    token_expiration = db.Column(db.DateTime, nullable=True)

    # Relationship with creations
    creations = db.relationship('Creation', backref='user', lazy=True)

    def __repr__(self):
        return f'<User {self.username}>'

    def get_time_saved_stats(self):
        """Calculate the total time saved in minutes and formatted as hours/minutes."""
        total_minutes = 0
        poem_counts = {'short': 0, 'medium': 0, 'long': 0, 'total': 0}
        
        for creation in self.creations:
            if creation.time_saved_minutes:
                total_minutes += creation.time_saved_minutes
                
            if creation.poem_length:
                poem_counts[creation.poem_length] += 1
                poem_counts['total'] += 1
            else:
                # For creations created before poem_length was added
                poem_counts['total'] += 1
        
        # Calculate hours and remaining minutes for display
        hours = total_minutes // 60
        minutes = total_minutes % 60
        
        return {
            'total_minutes': total_minutes,
            'hours': hours,
            'minutes': minutes,
            'poem_counts': poem_counts,
            'formatted': f"{hours} hours and {minutes} minutes" if hours > 0 else f"{minutes} minutes"
        }
        
    def get_poem_preferences(self):
        """Analyze user's poem type preferences and most downloaded poems."""
        poem_types = {}
        downloads = {
            'total': 0,
            'most_downloaded': None,
            'most_viewed': None,
            'recent': []
        }
        
        if not self.creations:
            return {'poem_types': {}, 'downloads': downloads}
            
        # Collect poem type stats and download information
        for creation in self.creations:
            # Track poem types
            if creation.poem_type:
                poem_types[creation.poem_type] = poem_types.get(creation.poem_type, 0) + 1
                
            # Track downloads
            if creation.is_downloaded:
                downloads['total'] += creation.download_count
                
            # Track the 5 most recent creations
            if len(downloads['recent']) < 5:
                downloads['recent'].append({
                    'id': creation.id,
                    'poem_type': creation.poem_type,
                    'created_at': creation.created_at,
                    'downloaded': creation.is_downloaded,
                    'download_count': creation.download_count,
                    'view_count': creation.view_count
                })
                
        # Find most downloaded poem
        most_downloaded = None
        most_downloaded_count = 0
        most_viewed = None
        most_viewed_count = 0
        
        for creation in self.creations:
            if creation.download_count > most_downloaded_count:
                most_downloaded = creation
                most_downloaded_count = creation.download_count
                
            if creation.view_count > most_viewed_count:
                most_viewed = creation
                most_viewed_count = creation.view_count
                
        if most_downloaded:
            downloads['most_downloaded'] = {
                'id': most_downloaded.id,
                'poem_type': most_downloaded.poem_type,
                'download_count': most_downloaded.download_count,
                'created_at': most_downloaded.created_at
            }
            
        if most_viewed:
            downloads['most_viewed'] = {
                'id': most_viewed.id,
                'poem_type': most_viewed.poem_type,
                'view_count': most_viewed.view_count,
                'created_at': most_viewed.created_at
            }
            
        # Sort poem types by popularity
        sorted_poem_types = sorted(poem_types.items(), key=lambda x: x[1], reverse=True)
        poem_types = {k: v for k, v in sorted_poem_types}
        
        return {
            'poem_types': poem_types,
            'downloads': downloads
        }
        
    def get_session_stats(self):
        """Get user's session statistics."""
        if not hasattr(self, 'sessions') or not self.sessions:
            return {
                'total_sessions': 0,
                'avg_duration_minutes': 0,
                'total_duration_hours': 0,
                'last_session': None
            }
            
        total_sessions = len(self.sessions)
        total_duration = sum(s.duration_seconds or 0 for s in self.sessions)
        avg_duration = total_duration / total_sessions if total_sessions > 0 else 0
        
        last_session = max(self.sessions, key=lambda s: s.session_start) if self.sessions else None
        
        return {
            'total_sessions': total_sessions,
            'avg_duration_minutes': round(avg_duration / 60, 1),
            'total_duration_hours': round(total_duration / 3600, 1),
            'last_session': last_session
        }

    def generate_password_reset_token(self, expires_in=3600):
        """Generate password reset token that expires in 1 hour by default"""
        return jwt.encode(
            {
                'reset_password': self.id,
                'exp': time.time() + expires_in
            },
            current_app.config['SECRET_KEY'],
            algorithm='HS256')

    @staticmethod
    def verify_password_reset_token(token):
        """Verify password reset token and return user if valid"""
        try:
            id = jwt.decode(token,
                            current_app.config['SECRET_KEY'],
                            algorithms=['HS256'])['reset_password']
        except Exception as e:
            current_app.logger.error(f"Token verification failed: {str(e)}")
            return None
        return User.query.get(id)

    def generate_verification_token(self):
        """Generate a verification token for email verification"""
        self.email_verification_token = secrets.token_urlsafe(32)
        # Token expires in 24 hours
        self.token_expiration = datetime.utcnow() + timedelta(hours=24)
        return self.email_verification_token

    def verify_email(self):
        """Mark user's email as verified"""
        self.is_email_verified = True
        self.email_verification_token = None
        self.token_expiration = None

    def is_token_valid(self, token):
        """Check if the verification token is valid"""
        if (self.email_verification_token is None
                or self.token_expiration is None or token is None):
            return False

        return (self.email_verification_token == token
                and self.token_expiration > datetime.utcnow())

    def set_password(self, password):
        """Set the password hash for the user."""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        """Check if the provided password matches the hash."""
        return check_password_hash(self.password_hash, password)


class Membership(db.Model):
    """Model for storing membership plan details."""
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)
    price = db.Column(db.Float, nullable=False)
    description = db.Column(db.Text, nullable=True)
    features = db.Column(db.JSON, nullable=True)
    max_poem_types = db.Column(db.Integer, nullable=False)
    max_frame_types = db.Column(db.Integer, nullable=False)
    stripe_price_id = db.Column(db.String(255), unique=True, nullable=True)
    max_saved_poems = db.Column(db.Integer, nullable=False)
    has_gallery = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f'<Membership {self.name}>'


class UserSession(db.Model):
    """Model for tracking user session information."""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    session_start = db.Column(db.DateTime, default=datetime.utcnow)
    session_end = db.Column(db.DateTime, nullable=True)
    duration_seconds = db.Column(db.Integer, nullable=True)
    ip_address = db.Column(db.String(50), nullable=True)
    user_agent = db.Column(db.String(255), nullable=True)
    pages_viewed = db.Column(db.Integer, default=0)
    
    # Relationship with user
    user = db.relationship('User', backref='sessions', lazy=True)
    
    def __repr__(self):
        return f'<UserSession {self.id}>'
    
    def end_session(self):
        """End the session and calculate duration."""
        self.session_end = datetime.utcnow()
        self.duration_seconds = int((self.session_end - self.session_start).total_seconds())
        return self.duration_seconds


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
    emphasis = db.Column(db.JSON, nullable=True)
    
    # Poem length classification and time saved tracking
    poem_length = db.Column(db.String(20), nullable=True)  # 'short', 'medium', 'long'
    time_saved_minutes = db.Column(db.Integer, nullable=True)  # Estimated time saved in minutes

    # Store creation timestamp
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Store a unique share code for public sharing
    share_code = db.Column(db.String(50), unique=True, nullable=True)
    
    # Metrics tracking
    is_downloaded = db.Column(db.Boolean, default=False)
    download_count = db.Column(db.Integer, default=0)
    view_count = db.Column(db.Integer, default=0)
    last_viewed_at = db.Column(db.DateTime, nullable=True)
    last_downloaded_at = db.Column(db.DateTime, nullable=True)

    __table_args__ = (
        db.Index('ix_creation_user_id', 'user_id'),
        db.Index('ix_creation_created_at', 'created_at'),
        db.Index('ix_creation_user_created', 'user_id', 'created_at'),
        db.Index('ix_creation_poem_type', 'poem_type'),
        db.Index('ix_creation_downloaded', 'is_downloaded'),
    )

    def __repr__(self):
        return f'<Creation {self.id}, created at {self.created_at}>'

    def generate_share_code(self):
        """Generate a unique share code for this creation."""
        if not self.share_code:
            # Generate a random 10-character code
            code = ''.join(
                random.choices(string.ascii_uppercase + string.digits, k=10))
            self.share_code = code
            return code
        return self.share_code
        
    def increment_download_count(self):
        """Increment the download count for this creation."""
        self.download_count += 1
        self.is_downloaded = True
        self.last_downloaded_at = datetime.utcnow()
        return self.download_count
        
    def increment_view_count(self):
        """Increment the view count for this creation."""
        self.view_count += 1
        self.last_viewed_at = datetime.utcnow()
        return self.view_count


class ContactMessage(db.Model):
    """Model for storing contact form submissions."""
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), nullable=False)
    subject = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_read = db.Column(db.Boolean, default=False)
    responded = db.Column(db.Boolean, default=False)

    def __repr__(self):
        return f'<ContactMessage {self.subject} from {self.email}>'


class Transaction(db.Model):
    """Model for storing payment transactions."""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20),
                       nullable=False)  # 'completed', 'pending', 'failed'
    payment_method = db.Column(db.String(50), nullable=True)
    currency = db.Column(db.String(3), nullable=False, default='USD')
    transaction_id = db.Column(db.String(100),
                               nullable=True)  
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Foreign key to the Membership table
    membership_id = db.Column(db.Integer,
                              db.ForeignKey('membership.id'),
                              nullable=True)

    # Relationship with user
    user = db.relationship('User', backref='transactions')
    membership = db.relationship('Membership', backref='transactions')

    def __repr__(self):
        return f'<Transaction {self.id}>'


class PoemLength(db.Model):
    """Model for storing poem length options and restrictions"""
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)
    display_name = db.Column(db.String(50), nullable=False)
    line_range = db.Column(db.String(50), nullable=False)
    is_premium = db.Column(db.Boolean, default=False)
    order = db.Column(db.Integer, default=0)

    def __repr__(self):
        return f'<PoemLength {self.name}>'


# Admin-related models
class AdminRole(db.Model):
    """Model for admin roles and permissions"""
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False, unique=True)
    description = db.Column(db.String(255))
    
    # Permissions as JSON field
    permissions = db.Column(db.JSON, nullable=False, default=dict)
    
    # Relationships
    users = db.relationship('AdminUser', backref='role', lazy=True)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<AdminRole {self.name}>'


class AdminUser(db.Model):
    """Model for admin users with role-based permissions"""
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    
    # Role relationship
    role_id = db.Column(db.Integer, db.ForeignKey('admin_role.id'), nullable=False)
    
    is_active = db.Column(db.Boolean, default=True)
    last_login = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<AdminUser {self.username}>'
    
    def set_password(self, password):
        """Set the password hash for the admin user."""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Check if the provided password matches the hash."""
        return check_password_hash(self.password_hash, password)
        
    def has_permission(self, permission):
        """Check if the admin has a specific permission"""
        if not self.role or not self.role.permissions:
            return False
        return permission in self.role.permissions.get('allowed', [])


class AdminLog(db.Model):
    """Model for tracking admin activity"""
    id = db.Column(db.Integer, primary_key=True)
    admin_id = db.Column(db.Integer, db.ForeignKey('admin_user.id'), nullable=False)
    action = db.Column(db.String(100), nullable=False)
    entity_type = db.Column(db.String(50), nullable=True)  # e.g., 'user', 'membership', etc.
    entity_id = db.Column(db.Integer, nullable=True)
    details = db.Column(db.JSON, nullable=True)
    ip_address = db.Column(db.String(50), nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationship
    admin = db.relationship('AdminUser', backref='logs', lazy=True)
    
    def __repr__(self):
        return f'<AdminLog {self.action} by {self.admin_id} at {self.timestamp}>'
