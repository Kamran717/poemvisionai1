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
            
        # If from_email not specified, use default sender from app config
        if from_email is None:
            from_email = current_app.config.get('MAIL_DEFAULT_SENDER', 'noreply@poemvision.com')
            
        # Ensure from_email is just the email part if it contains a display name
        if '<' in from_email and '>' in from_email:
            display_name = from_email.split('<')[0].strip()
            email_address = from_email.split('<')[1].split('>')[0].strip()
            from_email_obj = Email(email_address, display_name)
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
        
        return response.status_code in [200, 201, 202]
        
    except Exception as e:
        current_app.logger.error(f"SendGrid error: {e}")
        return False