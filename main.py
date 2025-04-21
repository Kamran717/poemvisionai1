import os
import logging
from flask import Flask
from werkzeug.security import generate_password_hash

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Import app and db
from app import app
from models import db, AdminUser, AdminRole

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
            
            # Create default admin roles and users
            create_default_admin_roles()
            create_default_admin_user()

            # Verify creation
            from models import Membership
            plan_count = Membership.query.count()
            logger.info(f"Database initialized with {plan_count} membership plans")

        except Exception as e:
            logger.error(f"Database initialization failed: {str(e)}", exc_info=True)
            raise
            
def create_default_admin_roles():
    """Create default admin roles if they don't exist"""
    # Check if admin roles already exist
    if AdminRole.query.count() > 0:
        logger.info("Admin roles already exist, skipping creation.")
        return
    
    # Super Admin role with all permissions
    super_admin_permissions = {
        'allowed': [
            'view_users', 'edit_users', 'delete_users',
            'view_memberships', 'edit_memberships',
            'view_financial', 'process_refunds',
            'view_analytics',
            'view_admins', 'edit_admins',
            'view_roles', 'edit_roles',
            'view_logs'
        ]
    }
    
    # Support Staff role with limited permissions
    support_staff_permissions = {
        'allowed': [
            'view_users', 'edit_users',
            'view_memberships',
            'view_analytics',
            'view_logs'
        ]
    }
    
    # Marketing Manager role with analytics/content permissions
    marketing_permissions = {
        'allowed': [
            'view_analytics',
            'view_users',
            'view_financial'
        ]
    }
    
    # Create the roles
    roles = [
        AdminRole(name='Super Admin', description='Full administrative access', permissions=super_admin_permissions),
        AdminRole(name='Support Staff', description='User management and support', permissions=support_staff_permissions),
        AdminRole(name='Marketing Manager', description='Analytics and reporting', permissions=marketing_permissions)
    ]
    
    # Add roles to database
    for role in roles:
        db.session.add(role)
    
    db.session.commit()
    logger.info(f"Created {len(roles)} default admin roles")


def create_default_admin_user():
    """Create a default admin user if none exists"""
    # Check if any admin user already exists
    if AdminUser.query.count() > 0:
        logger.info("Admin users already exist, skipping creation.")
        return
    
    # Get the Super Admin role
    super_admin_role = AdminRole.query.filter_by(name='Super Admin').first()
    
    if not super_admin_role:
        logger.error("Super Admin role not found, cannot create default admin user")
        return
    
    # Get admin credentials from environment, or use defaults for development
    admin_username = os.environ.get('ADMIN_USERNAME', 'admin')
    admin_email = os.environ.get('ADMIN_EMAIL', 'admin@poemvision.ai')
    admin_password = os.environ.get('ADMIN_PASSWORD', 'poemvision2025')
    
    # Create the default admin user
    admin_user = AdminUser(
        username=admin_username,
        email=admin_email,
        role_id=super_admin_role.id
    )
    admin_user.password_hash = generate_password_hash(admin_password)
    
    # Add admin user to database
    db.session.add(admin_user)
    db.session.commit()
    
    logger.info(f"Created default admin user: {admin_username}")

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