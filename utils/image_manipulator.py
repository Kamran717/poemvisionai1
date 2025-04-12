import io
import logging
from PIL import Image, ImageDraw, ImageFont
import base64

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
        image_area_height = original_height * (target_width / original_width)
        
        # Format poem lines
        poem_lines = poem_text.strip().split("\n")
        
        # Increase font size dramatically to match example
        # Using a much larger font size (60-70pt) based on the example
        poem_font_size = max(60, int(target_width * 0.08))
        
        # Calculate line height - in the example there's good spacing between lines
        poem_line_height = int(poem_font_size * 1.3)
        
        # Calculate poem area height - much larger to accommodate bigger text
        # The example shows the text taking up most of the white area
        poem_padding = 80
        poem_height = (len(poem_lines) * poem_line_height) + poem_padding * 2
        
        # Create a new image with white background
        new_width = target_width
        new_height = int(image_area_height + poem_height)
        
        # Create the new image with white background
        final_img = Image.new("RGB", (new_width, new_height), (255, 255, 255))
        
        # Resize the original image to fit the target width
        img_resized = img.resize((int(target_width), int(image_area_height)), Image.LANCZOS)
        
        # Paste the resized image at the top
        final_img.paste(img_resized, (0, 0))
        
        # Create draw object
        draw = ImageDraw.Draw(final_img)
        
        # Try loading a nice serif font that matches the example
        # The example uses a classic serif font with nice contrast
        try:
            # Prioritize Georgia which closely matches the example
            font_options = [
                "Georgia.ttf",
                "Times New Roman.ttf",
                "DejaVuSerif.ttf",
                "LiberationSerif-Regular.ttf",
                "Arial.ttf"
            ]
            
            font = None
            for font_name in font_options:
                try:
                    font = ImageFont.truetype(font_name, size=poem_font_size)
                    break
                except:
                    continue
            
            if font is None:
                font = ImageFont.load_default()
                logger.warning("Using default font - none of the TrueType fonts were available")
        except Exception as e:
            logger.error(f"Error loading font: {str(e)}")
            font = ImageFont.load_default()
        
        # Set starting position for the poem text
        # In the example, there's a good amount of spacing after the image
        text_y = int(image_area_height + poem_padding)
        
        # Draw each line of the poem with large text
        for i, line in enumerate(poem_lines):
            # Calculate text width for centering
            try:
                line_width = draw.textlength(line, font=font)
            except:
                # For older PIL versions that don't have textlength
                try:
                    line_width = font.getmask(line).getbbox()[2]
                except:
                    line_width = len(line) * (poem_font_size * 0.6)
            
            # Center each line of text like in the example
            text_x = (new_width - line_width) // 2
            line_y = text_y + (i * poem_line_height)
            
            # Draw the poem text in pure black like in the example
            draw.text((text_x, line_y), line, font=font, fill=(0, 0, 0))
        
        # Save the final image
        output = io.BytesIO()
        final_img.save(output, format="JPEG", quality=95)
        return output.getvalue()
    
    except Exception as e:
        logger.error(f"Error creating final image: {str(e)}")
        # Return the original image if there's an error
        return image_bytes