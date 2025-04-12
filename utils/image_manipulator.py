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
        poem_font_size = 200  # MUCH larger text size for maximum readability
        
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
        # Cap the width to ensure text doesn't get too wide on images with different aspect ratios
        target_width = max(original_width, 1200) # Ensure minimum width for text
        target_width = min(target_width, 1800)  # But cap maximum width to prevent excessive stretching
        
        # Calculate image scaling to ensure it fits within the frame
        image_area_width = target_width
        image_area_height = original_height * (image_area_width / original_width)
        
        # Now set the final dimensions - ensure all values are integers
        new_width = int(image_area_width + (frame_width * 2) + (padding * 2))
        new_height = int(image_area_height + (frame_width * 2) + (padding * 2) + poem_height)
        
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
        
        # Resize the image to fit while maintaining aspect ratio
        img_resized = img.resize((int(image_area_width), int(image_area_height)), Image.LANCZOS)
        
        # Paste the resized image
        framed_img.paste(img_resized, (paste_x, paste_y))
        
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
            # Convert all values to integers for the range function
            for i in range(frame_width, int(new_width - frame_width), pattern_spacing):
                # Fix rectangle coordinates format (x1, y1, x2, y2)
                draw.rectangle((i, frame_width//2, i + 10, frame_width), fill=frame_color)
                draw.rectangle((i, new_height - frame_width, i + 10, new_height - frame_width//2), fill=frame_color)
            
            # Convert all values to integers for the range function
            for i in range(frame_width, int(new_height - frame_width), pattern_spacing):
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
        
        # Calculate text position (centered below the resized image)
        text_y = int(paste_y + image_area_height + padding)
        
        # Draw each line of the poem with improved visibility
        text_color = (0, 0, 0)  # Black text
        text_shadow_color = (230, 230, 230)  # Lighter shadow for stronger contrast
        
        # Stronger contrast for better readability
        background_rect_padding = 10  # Padding around text
        
        # Calculate the area for poem text
        poem_bg_y = text_y - background_rect_padding*2
        poem_bg_height = (len(poem_lines) * poem_line_height) + (background_rect_padding * 4)
        
        # Find the longest line to ensure all text fits within a symmetrical area
        max_line_width = 0
        for line in poem_lines:
            line_width = draw.textlength(line, font=font)
            max_line_width = max(max_line_width, line_width)
        
        # Add padding around the longest line
        poem_area_width = max_line_width + (padding * 4)
        poem_bg_x1 = (new_width - poem_area_width) // 2
        poem_bg_x2 = poem_bg_x1 + poem_area_width
        
        # Add a subtle background for the poem area - light cream color for elegance
        draw.rectangle(
            (poem_bg_x1, poem_bg_y, poem_bg_x2, poem_bg_y + poem_bg_height),
            fill=(250, 250, 245),  # Very light cream color
            outline=None
        )
        
        # Add a thin decorative border around the poem area
        draw.rectangle(
            (poem_bg_x1, poem_bg_y, poem_bg_x2, poem_bg_y + poem_bg_height),
            fill=None,
            outline=(200, 200, 200),  # Light gray border
            width=2
        )
        
        # Add a header line to separate the image from the poem
        draw.line(
            [(frame_width + padding, poem_bg_y - 2), (new_width - frame_width - padding, poem_bg_y - 2)],
            fill=(180, 180, 180),
            width=1
        )
        
        for i, line in enumerate(poem_lines):
            # Calculate text position for this line - centered within the poem area
            line_width = draw.textlength(line, font=font)
            text_x = (new_width - line_width) // 2
            line_y = text_y + (i * poem_line_height)
            
            # Draw text with subtle shadow for depth without overwhelming contrast
            # Shadow first - dark gray
            draw.text((text_x + 2, line_y + 2), line, fill=(150, 150, 150), font=font)
            
            # Then the main text - pure black for clarity
            draw.text((text_x, line_y), line, fill=(0, 0, 0), font=font)
        
        # Convert the image to bytes
        output_buffer = io.BytesIO()
        framed_img.save(output_buffer, format="JPEG", quality=85)
        output_buffer.seek(0)
        
        return output_buffer.getvalue()
    
    except Exception as e:
        logger.error(f"Error creating framed image: {str(e)}", exc_info=True)
        raise
