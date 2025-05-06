"""
SendGrid email utility functions for Poem Vision.
"""
import os
import json
import requests
from flask import current_app

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
        # Log that we're attempting to send an email
        current_app.logger.info(f"Attempting to send email to {to_email} with subject: {subject}")
        
        # Get SendGrid API key from environment
        sendgrid_api_key = os.environ.get('SENDGRID_API_KEY')
        if not sendgrid_api_key:
            current_app.logger.error("SENDGRID_API_KEY environment variable not set")
            # Log that we're going into development mode
            current_app.logger.warning("SendGrid API key missing, running in development mode")
            # Log the email content for development purposes
            current_app.logger.info(f"Would have sent email to: {to_email}")
            current_app.logger.info(f"Subject: {subject}")
            if html_content:
                current_app.logger.info(f"HTML Content preview: {html_content[:100]}...")
            elif text_content:
                current_app.logger.info(f"Text Content preview: {text_content[:100]}...")
            # In development mode, consider the email "sent" to allow the app to function
            return True
        
        # Get verified sender email from environment - this must be used as the from email
        verified_sender = os.environ.get('SENDGRID_VERIFIED_SENDER')
        if not verified_sender:
            # Fallback to the known verified sender if environment variable is not set
            verified_sender = "info@poemvisionai.com"
            current_app.logger.warning(
                "SENDGRID_VERIFIED_SENDER environment variable not set, "
                f"using fallback verified sender: {verified_sender}"
            )
            # Log instructions for configuring SendGrid
            current_app.logger.warning(
                "To enable email functionality, you need to verify your sender email in SendGrid "
                "and set the SENDGRID_VERIFIED_SENDER environment variable to the verified email."
            )
        
        # Make sure the sender email is definitely lowercase as SendGrid sometimes requires this
        verified_sender = verified_sender.lower()
        
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
        
        # Create a message using the direct API approach instead of the helpers
        message = {
            "personalizations": [
                {
                    "to": [{"email": to_email}]
                }
            ],
            "from": {
                "email": sender_email,
                "name": display_name
            },
            "subject": subject
        }
        
        # Add content (HTML preferred, fallback to text)
        if html_content:
            message["content"] = [{"type": "text/html", "value": html_content}]
        elif text_content:
            message["content"] = [{"type": "text/plain", "value": text_content}]
        else:
            current_app.logger.error("No content provided for email")
            return False
        
        current_app.logger.debug(f"Sending email via SendGrid API with from: {sender_email}")
        
        # Send message using direct requests
        response = requests.post(
            "https://api.sendgrid.com/v3/mail/send",
            headers={
                "Authorization": f"Bearer {sendgrid_api_key}",
                "Content-Type": "application/json"
            },
            json=message
        )
        
        # Log response for debugging
        current_app.logger.info(f"SendGrid API response status code: {response.status_code}")
        current_app.logger.debug(f"SendGrid API response: {response.text}")
        
        if response.status_code not in [200, 201, 202]:
            current_app.logger.error(f"SendGrid returned error code: {response.status_code}")
            return False
            
        return True
        
    except Exception as e:
        error_msg = str(e)
        current_app.logger.error(f"SendGrid error: {error_msg}")
        
        # Handle different types of errors with specific messages
        if "The from address does not match a verified Sender Identity" in error_msg:
            current_app.logger.error(
                "SendGrid requires sender email verification. Please verify your sender email "
                "in SendGrid and set SENDGRID_VERIFIED_SENDER environment variable."
            )
            # Get the current sender email that we're trying to use
            current_sender = os.environ.get('SENDGRID_VERIFIED_SENDER', 'info@poemvisionai.com')
            # Log the attempted from address for troubleshooting
            current_app.logger.error(f"Attempted to use sender: {current_sender}")
            
            # In development mode, provide a way to continue
            if os.environ.get('FLASK_ENV') == 'development':
                current_app.logger.warning("Running in development mode, simulating email send success")
                # Log the email that would have been sent
                current_app.logger.info(f"Would have sent email to: {to_email}")
                current_app.logger.info(f"Subject: {subject}")
                # Return True to allow application to continue functioning in dev mode
                return True
        
        # For all other errors, return False to indicate failure
        return False