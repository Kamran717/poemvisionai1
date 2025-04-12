import io
import logging
import os
from PIL import Image, ImageDraw, ImageFont

# Set up logging
logger = logging.getLogger(__name__)

def create_framed_image(image_bytes, poem_text, frame_style="classic"):
    """
    Create a minimalist image with the poem text below it.
    Matches the example design with large, spaced text with the image dominant.
    
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
        
        # Format poem lines - only keep non-empty lines
        poem_lines = [line for line in poem_text.strip().split("\n") if line.strip()]
        
        # Count lines for spacing calculation
        line_count = len(poem_lines)
        
        # First, determine image height maintaining aspect ratio
        image_area_height = int(original_height * (target_width / original_width))
        
        # Make image take up exactly 70% of the total composition height
        # This ensures image is dominant as requested
        
        # STRICTLY enforce the 70/30 ratio as requested
        target_image_ratio = 0.70  # Image takes exactly 70% of total height
        
        # Calculate total height based on the image height and the 70% ratio
        total_height = int(image_area_height / target_image_ratio)
        
        # Text section is exactly 30% of the total height
        text_section_height = int(total_height * 0.30)
        
        # Calculate font size based on the 30% text area and number of lines
        # This ensures the text will properly fit in the allocated space
        if line_count > 0:
            # Calculate available height for text block (minus some padding)
            available_text_height = text_section_height * 0.9  # Use 90% of the text section
            
            # Font size determined by available height divided by lines
            # with adjustment for line spacing - further reduced
            ideal_font_size = available_text_height / (line_count * 1.4)
            
            # Scale by width - REDUCED to make text smaller
            width_based_font_size = target_width * 0.06  # Reduced from 0.08
            
            # Use the smaller of the two to ensure it fits
            poem_font_size = min(int(ideal_font_size), int(width_based_font_size))
            
            # Reduced minimum size to ensure everything fits
            poem_font_size = max(20, poem_font_size)  # Reduced from 24
            
            # Apply more significant reductions for longer poems
            if line_count > 6:
                poem_font_size = int(poem_font_size * 0.7)
            elif line_count > 4:
                poem_font_size = int(poem_font_size * 0.8)
        else:
            # Default if no lines (shouldn't happen)
            poem_font_size = max(24, int(target_width * 0.07))
        
        # Reduce line spacing to ensure all text fits (reduced from 1.8x to 1.4x)
        poem_line_height = int(poem_font_size * 1.4)
        
        # We already calculated these values earlier, no need to repeat
            
        # Create final image with white background
        final_img = Image.new("RGB", (target_width, total_height), (255, 255, 255))
        
        # Resize and paste the original image at the top
        img_resized = img.resize((target_width, image_area_height), Image.LANCZOS)
        final_img.paste(img_resized, (0, 0))
        
        # Create draw object
        draw = ImageDraw.Draw(final_img)
        
        # Try to find a suitable font
        try:
            # Try these common fonts
            font_paths = [
                # Full paths for Linux
                "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
                "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
                # Common font names
                "Georgia.ttf", 
                "times.ttf", 
                "Times New Roman.ttf", 
                "DejaVuSerif.ttf",
                "LiberationSerif-Regular.ttf"
            ]
            
            # Try each font in order
            font = None
            for font_path in font_paths:
                try:
                    font = ImageFont.truetype(font_path, size=poem_font_size)
                    logger.info(f"Using font: {font_path}")
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
        
        # Position text to start immediately after the image
        # and center it vertically within the 30% text section
        
        # Calculate the total height needed for all text lines
        total_text_lines_height = len(poem_lines) * poem_line_height
        
        # Figure out how much vertical space we have for text
        available_text_space = text_section_height
        
        # Center the text block vertically in the available space
        vertical_padding = (available_text_space - total_text_lines_height) / 2
        vertical_padding = max(10, vertical_padding)  # Ensure at least a small margin
        
        # Set the starting y position for text
        text_y = image_area_height + vertical_padding
        
        # Check if we're using the default font (which needs special handling)
        using_default_font = str(font) == str(ImageFont.load_default())
        
        # Draw each line of the poem with proper alignment
        for i, line in enumerate(poem_lines):
            # Left align text with proper margin (12% from left edge)
            text_x = int(target_width * 0.12)
            line_y = text_y + (i * poem_line_height)
            
            # For default font (which is small), create a much larger appearance
            if using_default_font:
                # Calculate an appropriate thickness based on font size
                thickness = max(10, poem_font_size // 4)
                
                # Draw multiple times with slight offsets to create thickness
                # First create a shadow/outline effect to make text appear much larger
                for dx in range(-thickness, thickness+1, 2):
                    for dy in range(-thickness, thickness+1, 2):
                        # Draw outline in very light gray
                        draw.text((text_x+dx, line_y+dy), line, fill=(200, 200, 200), font=font)
                
                # Then draw a thicker black text on top
                for dx in range(-thickness//2, thickness//2+1):
                    for dy in range(-thickness//2, thickness//2+1):
                        draw.text((text_x+dx, line_y+dy), line, fill=(0, 0, 0), font=font)
                
                # Finally draw the core text for maximum clarity
                draw.text((text_x, line_y), line, fill=(0, 0, 0), font=font)
            else:
                # Draw normal text with the proper font
                draw.text((text_x, line_y), line, fill=(0, 0, 0), font=font)
        
        # Save the final image with high quality
        output = io.BytesIO()
        final_img.save(output, format="JPEG", quality=95)
        return output.getvalue()
    
    except Exception as e:
        logger.error(f"Error creating final image: {str(e)}")
        # Return the original image if there's an error
        return image_bytes