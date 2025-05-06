"""
SendGrid email utility functions for Poem Vision.
"""
import os
from flask import current_app
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content

def send_email(
    to_email,
    subject,
    text_content=None,
    html_content=None,
    from_email=None
):
    """
    Send an email using SendGrid API.
    
    Args:
        to_email (str): Recipient email address
        subject (str): Email subject
        text_content (str, optional): Plain text content
        html_content (str, optional): HTML content
        from_email (str, optional): Sender email address, defaults to app config
        
    Returns:
        bool: True if email was sent successfully, False otherwise
    """
    try:
        # Get SendGrid API key from environment
        sendgrid_api_key = os.environ.get('SENDGRID_API_KEY')
        if not sendgrid_api_key:
            current_app.logger.error("SENDGRID_API_KEY environment variable not set")
            return False
        
        # Get verified sender email from environment - this must be used as the from email
        verified_sender = os.environ.get('SENDGRID_VERIFIED_SENDER')
        if not verified_sender:
            current_app.logger.error("SENDGRID_VERIFIED_SENDER environment variable not set")
            return False
        
        # Get display name from the from_email or config
        display_name = "Poem Vision"
        sender_email = verified_sender  # Always use the verified sender email
        
        # Try to extract display name from from_email if provided
        if from_email and '<' in from_email and '>' in from_email:
            display_name = from_email.split('<')[0].strip()
        elif from_email and '@' not in from_email:
            # If from_email looks like just a name without email
            display_name = from_email
        elif from_email is None and current_app.config.get('MAIL_DEFAULT_SENDER'):
            # Try to get display name from default sender config
            default_sender = current_app.config.get('MAIL_DEFAULT_SENDER')
            if '<' in default_sender and '>' in default_sender:
                display_name = default_sender.split('<')[0].strip()
        
        # Create a sender object with the verified email and display name
        current_app.logger.debug(f"Using verified sender email: {sender_email} with display name: {display_name}")
        from_email_obj = Email(sender_email, display_name) 
            
        # Create message
        message = Mail(
            from_email=from_email_obj,
            to_emails=To(to_email),
            subject=subject
        )

        # Add content (HTML preferred, fallback to text)
        if html_content:
            message.content = Content("text/html", html_content)
        elif text_content:
            message.content = Content("text/plain", text_content)
        else:
            current_app.logger.error("No content provided for email")
            return False

        # Send message
        sg = SendGridAPIClient(sendgrid_api_key)
        response = sg.send(message)
        
        # Log response for debugging
        current_app.logger.info(f"SendGrid API response status code: {response.status_code}")
        
        if response.status_code not in [200, 201, 202]:
            current_app.logger.error(f"SendGrid returned error code: {response.status_code}")
            return False
            
        return True
        
    except Exception as e:
        current_app.logger.error(f"SendGrid error: {e}")
        if "The from address does not match a verified Sender Identity" in str(e):
            current_app.logger.error(
                "SendGrid requires sender email verification. Please verify your sender email "
                "in SendGrid and set SENDGRID_VERIFIED_SENDER environment variable."
            )
        return False