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
        
        # Get verified sender email from environment or config
        verified_sender = os.environ.get('SENDGRID_VERIFIED_SENDER')
        
        # If from_email not specified or no verified sender in environment, use default
        if from_email is None:
            # Use verified sender from environment if available
            if verified_sender:
                from_email = verified_sender
            else:
                from_email = current_app.config.get('MAIL_DEFAULT_SENDER', 'noreply@poemvision.com')
                current_app.logger.warning(
                    "SENDGRID_VERIFIED_SENDER environment variable not set. "
                    "Using default sender, which may fail if not verified in SendGrid."
                )
            
        # Extract display name and email address if in format "Name <email@example.com>"
        if '<' in from_email and '>' in from_email:
            display_name = from_email.split('<')[0].strip()
            email_address = from_email.split('<')[1].split('>')[0].strip()
            
            # If verified sender is set, use that email with original display name
            if verified_sender and '<' in verified_sender and '>' in verified_sender:
                verified_email = verified_sender.split('<')[1].split('>')[0].strip()
                from_email_obj = Email(verified_email, display_name)
            else:
                from_email_obj = Email(email_address, display_name)
        else:
            # No display name in the from_email
            if verified_sender and '<' not in verified_sender:
                # Just use the verified sender directly
                from_email_obj = Email(verified_sender)
            else:
                from_email_obj = Email(from_email)
            
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