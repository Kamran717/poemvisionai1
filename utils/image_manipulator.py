import io
import logging
import os
from PIL import Image, ImageDraw, ImageFont

# Set up logging
logger = logging.getLogger(__name__)

def create_framed_image(image_bytes, poem_text, frame_style="classic"):
    """
    Create a minimalist image with the poem text below it.
    Matches the example design with very large text covering most of the white space.
    
    Args:
        image_bytes: The binary data of the image
        poem_text (str): The poem text to add below the image
        frame_style (str): The style of frame to use (ignored in minimalist design)
        
    Returns:
        bytes: The binary data of the created image with poem
    """
    try:
        # Load the image
        img = Image.open(io.BytesIO(image_bytes))
        
        # Calculate dimensions for the final image
        original_width, original_height = img.size
        
        # Set a reasonable width (don't make it too wide)
        target_width = min(original_width, 800)
        
        # Calculate new height to maintain aspect ratio
        image_area_height = int(original_height * (target_width / original_width))
        
        # Format poem lines - only keep non-empty lines
        poem_lines = [line for line in poem_text.strip().split("\n") if line.strip()]
        
        # VERY LARGE text size - at least 48pt, up to 20% of image width
        poem_font_size = max(48, int(target_width * 0.15))
        
        # Calculate line height (space between lines) - make it much larger
        # The example shows significant line spacing
        poem_line_height = int(poem_font_size * 2.0)
        
        # Add generous whitespace after image and at bottom
        poem_padding_top = int(poem_font_size * 1.2)  
        poem_padding_bottom = int(poem_font_size * 3.0)
        
        # Calculate poem area height - include empty space
        poem_height = (len(poem_lines) * poem_line_height) + poem_padding_top + poem_padding_bottom
        
        # Create dimensions for the new image
        new_width = target_width
        new_height = int(image_area_height + poem_height)
        
        # Create the new image with white background
        final_img = Image.new("RGB", (new_width, new_height), (255, 255, 255))
        
        # Resize and paste the original image at the top
        img_resized = img.resize((int(target_width), int(image_area_height)), Image.LANCZOS)
        final_img.paste(img_resized, (0, 0))
        
        # Create draw object
        draw = ImageDraw.Draw(final_img)
        
        # Try to load a font
        try:
            # Try a few common serif fonts first
            font_options = [
                "Georgia.ttf", 
                "times.ttf", 
                "Times New Roman.ttf", 
                "DejaVuSerif.ttf"
            ]
            
            # Try each font in order
            font = None
            for font_name in font_options:
                try:
                    font = ImageFont.truetype(font_name, size=poem_font_size)
                    break
                except:
                    continue
            
            # If no font found, use default
            if font is None:
                font = ImageFont.load_default()
                logger.warning("Using default font - no TrueType fonts available")
                
        except Exception as e:
            logger.error(f"Error loading font: {str(e)}")
            font = ImageFont.load_default()
        
        # Set starting position for the poem text
        text_y = int(image_area_height + poem_padding_top)
        
        # If we're using the default font, make it appear much larger
        using_default_font = str(font) == str(ImageFont.load_default())
        
        # Draw each line of the poem with large text
        for i, line in enumerate(poem_lines):
            # Left align text with a margin (12% from left)
            text_x = int(new_width * 0.12)
            line_y = text_y + (i * poem_line_height)
            
            # If using default font, create a larger appearance by drawing multiple times
            if using_default_font:
                # Using thicker/larger text with the default font
                thickness = 6  # Larger number = thicker text
                for dx in range(-thickness, thickness+1):
                    for dy in range(-thickness, thickness+1):
                        draw.text((text_x+dx, line_y+dy), line, fill=(0, 0, 0), font=font)
            else:
                # Draw normal text with the loaded font
                draw.text((text_x, line_y), line, fill=(0, 0, 0), font=font)
        
        # Save the final image
        output = io.BytesIO()
        final_img.save(output, format="JPEG", quality=95)
        return output.getvalue()
    
    except Exception as e:
        logger.error(f"Error creating final image: {str(e)}")
        # Return the original image if there's an error
        return image_bytes