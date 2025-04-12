import io
import logging
from PIL import Image, ImageDraw, ImageFont
import base64

# Set up logging
logger = logging.getLogger(__name__)

def create_framed_image(image_bytes, poem_text, frame_style="classic"):
    """
    Create a framed image with the poem text.
    
    Args:
        image_bytes: The binary data of the image
        poem_text (str): The poem text to add to the image
        frame_style (str): The style of frame to use
        
    Returns:
        bytes: The binary data of the framed image
    """
    try:
        # Load the image
        img = Image.open(io.BytesIO(image_bytes))
        
        # Calculate dimensions for the final image (original image plus space for poem)
        original_width, original_height = img.size
        
        # Determine poem text size and layout
        padding = 40  # Padding around the image and text
        poem_height = 0
        poem_font_size = 72  # Increased by 100% from 36 to 72 for better readability
        
        # Create a larger canvas for the framed image with poem
        # The height is increased to accommodate the poem text below the image
        poem_lines = poem_text.strip().split("\n")
        # Ensure line height is 1.5 times the font size for readability
        poem_line_height = int(poem_font_size * 1.5)  # 1.5x font size for better line spacing
        poem_height = (len(poem_lines) * poem_line_height) + (padding * 2)
        
        # Calculate margins based on frame style
        frame_width = 20  # Default frame width
        if frame_style == "elegant":
            frame_width = 30
        elif frame_style == "minimalist":
            frame_width = 10
        elif frame_style == "ornate":
            frame_width = 40
        
        # Create a new image with the calculated dimensions
        # Adding space for the frame and the poem
        new_width = original_width + (frame_width * 2) + (padding * 2)
        new_height = original_height + (frame_width * 2) + (padding * 2) + poem_height
        
        # Frame color based on style
        frame_colors = {
            "classic": (50, 50, 50),      # Dark gray
            "elegant": (25, 25, 112),     # Midnight blue
            "vintage": (139, 69, 19),     # Saddle brown
            "minimalist": (200, 200, 200),# Light gray
            "ornate": (128, 0, 0)         # Maroon
        }
        
        frame_color = frame_colors.get(frame_style, (50, 50, 50))
        
        # Create the new image with white background
        framed_img = Image.new("RGB", (new_width, new_height), (255, 255, 255))
        draw = ImageDraw.Draw(framed_img)
        
        # Draw the frame
        draw.rectangle(
            (0, 0, new_width, new_height),  # Using (x1, y1, x2, y2) format
            fill=(255, 255, 255),
            outline=frame_color,
            width=frame_width
        )
        
        # Calculate position to paste the original image
        paste_x = frame_width + padding
        paste_y = frame_width + padding
        
        # Paste the original image
        framed_img.paste(img, (paste_x, paste_y))
        
        # Draw decorative elements based on frame style
        if frame_style == "elegant":
            # Draw elegant corners
            corner_size = 50
            draw.line([(frame_width, frame_width), (frame_width + corner_size, frame_width)], fill=frame_color, width=frame_width//2)
            draw.line([(frame_width, frame_width), (frame_width, frame_width + corner_size)], fill=frame_color, width=frame_width//2)
            
            draw.line([(new_width - frame_width, frame_width), (new_width - frame_width - corner_size, frame_width)], fill=frame_color, width=frame_width//2)
            draw.line([(new_width - frame_width, frame_width), (new_width - frame_width, frame_width + corner_size)], fill=frame_color, width=frame_width//2)
            
            draw.line([(frame_width, new_height - frame_width), (frame_width + corner_size, new_height - frame_width)], fill=frame_color, width=frame_width//2)
            draw.line([(frame_width, new_height - frame_width), (frame_width, new_height - frame_width - corner_size)], fill=frame_color, width=frame_width//2)
            
            draw.line([(new_width - frame_width, new_height - frame_width), (new_width - frame_width - corner_size, new_height - frame_width)], fill=frame_color, width=frame_width//2)
            draw.line([(new_width - frame_width, new_height - frame_width), (new_width - frame_width, new_height - frame_width - corner_size)], fill=frame_color, width=frame_width//2)
        
        elif frame_style == "ornate":
            # Draw ornate pattern along the frame
            pattern_spacing = 40
            for i in range(frame_width, new_width - frame_width, pattern_spacing):
                # Fix rectangle coordinates format (x1, y1, x2, y2)
                draw.rectangle((i, frame_width//2, i + 10, frame_width), fill=frame_color)
                draw.rectangle((i, new_height - frame_width, i + 10, new_height - frame_width//2), fill=frame_color)
            
            for i in range(frame_width, new_height - frame_width, pattern_spacing):
                # Fix rectangle coordinates format (x1, y1, x2, y2)
                draw.rectangle((frame_width//2, i, frame_width, i + 10), fill=frame_color)
                draw.rectangle((new_width - frame_width, i, new_width - frame_width//2, i + 10), fill=frame_color)
        
        # Add poem text below the image
        try:
            # Try to load one of several potential sans-serif fonts for better screen readability
            try_fonts = ["DejaVuSans.ttf", "arial.ttf", "Arial.ttf", "Helvetica.ttf", "Verdana.ttf",
                        "LiberationSans-Regular.ttf", "DejaVuSerif.ttf", "LiberationSerif-Regular.ttf"]
            
            font = None
            for font_name in try_fonts:
                try:
                    font = ImageFont.truetype(font_name, poem_font_size)
                    logger.debug(f"Successfully loaded font: {font_name}")
                    break
                except IOError:
                    continue
                    
            if font is None:
                # If no TrueType font was loaded, fall back to default
                font = ImageFont.load_default()
                logger.warning("Using default font - none of the TrueType fonts were available")
        except Exception as e:
            # If anything goes wrong, use the default font
            logger.error(f"Error loading font: {str(e)}")
            font = ImageFont.load_default()
        
        # Calculate text position (centered below the image)
        text_y = paste_y + original_height + padding
        
        # Draw each line of the poem with improved visibility
        text_color = (0, 0, 0)  # Black text
        text_shadow_color = (230, 230, 230)  # Lighter shadow for stronger contrast
        
        # Stronger contrast for better readability
        background_rect_padding = 10  # Padding around text
        
        # Draw a background rectangle for the entire poem area
        # for better text contrast and readability
        poem_bg_y = text_y - background_rect_padding
        poem_bg_height = (len(poem_lines) * poem_line_height) + (background_rect_padding * 2)
        draw.rectangle(
            (frame_width, poem_bg_y, new_width - frame_width, poem_bg_y + poem_bg_height),
            fill=(248, 248, 248),  # Very light gray background
            outline=None
        )
        
        for i, line in enumerate(poem_lines):
            # Calculate text position for this line
            line_width = draw.textlength(line, font=font)
            text_x = (new_width - line_width) // 2
            line_y = text_y + (i * poem_line_height)
            
            # Create a background rectangle just for this line for better contrast
            line_bg_padding = 10
            draw.rectangle(
                (text_x - line_bg_padding, 
                 line_y - line_bg_padding,
                 text_x + line_width + line_bg_padding,
                 line_y + poem_font_size + line_bg_padding),
                fill=(250, 250, 250),  # Almost white background
                outline=None
            )
            
            # Draw the main text with improved contrast - no need for shadows with the background
            draw.text((text_x, line_y), line, fill=(0, 0, 0), font=font)  # Pure black text
        
        # Convert the image to bytes
        output_buffer = io.BytesIO()
        framed_img.save(output_buffer, format="JPEG", quality=85)
        output_buffer.seek(0)
        
        return output_buffer.getvalue()
    
    except Exception as e:
        logger.error(f"Error creating framed image: {str(e)}", exc_info=True)
        raise
