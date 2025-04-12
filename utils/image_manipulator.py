import io
import logging
import os
import hashlib
import functools
from PIL import Image, ImageDraw, ImageFont

# Set up logging
logger = logging.getLogger(__name__)

# Cache for framed images to improve performance
# This prevents regenerating the same image multiple times
IMAGE_CACHE = {}

# Maximum number of images to keep in cache to prevent memory issues
MAX_CACHE_SIZE = 50

# Function to trim cache if it gets too large
def trim_cache():
    """
    Remove oldest entries from cache if it exceeds the maximum size.
    """
    global IMAGE_CACHE
    if len(IMAGE_CACHE) > MAX_CACHE_SIZE:
        # Sort keys by time added and keep only the newest MAX_CACHE_SIZE entries
        logger.info(f"Trimming image cache from {len(IMAGE_CACHE)} to {MAX_CACHE_SIZE} entries")
        # Simple approach: just clear half the cache when it gets full
        keys_to_remove = list(IMAGE_CACHE.keys())[:(len(IMAGE_CACHE) - MAX_CACHE_SIZE)]
        for key in keys_to_remove:
            del IMAGE_CACHE[key]

def create_framed_image(image_bytes, poem_text, frame_style="classic"):
    """
    Create a minimalist image with the poem text below it.
    Matches the example design with large, spaced text with the image dominant.
    Implements caching to avoid regenerating the same image multiple times.
    
    Args:
        image_bytes: The binary data of the image
        poem_text (str): The poem text to add below the image
        frame_style (str): The style of frame to use (ignored in minimalist design)
        
    Returns:
        bytes: The binary data of the created image with poem
    """
    # Create a cache key based on the input parameters
    # Use blake2b hash for faster hashing of large binary data
    cache_key = hashlib.blake2b(digest_size=16)
    cache_key.update(image_bytes)
    cache_key.update(poem_text.encode('utf-8'))
    cache_key.update(frame_style.encode('utf-8'))
    key = cache_key.hexdigest()
    
    # Check if we have this image already cached
    if key in IMAGE_CACHE:
        logger.info(f"Using cached framed image for key: {key[:8]}...")
        return IMAGE_CACHE[key]
    
    # Not in cache, generate the image
    try:
        # Load the image
        img = Image.open(io.BytesIO(image_bytes))
        
        # Calculate dimensions for the final image
        original_width, original_height = img.size
        
        # Set a width that can accommodate the text
        # Increased width to prevent text truncation
        target_width = min(original_width, 1000)
        
        # Format poem lines - only keep non-empty lines
        raw_lines = [line for line in poem_text.strip().split("\n") if line.strip()]
        
        # Check for any excessively long lines that need wrapping
        poem_lines = []
        max_chars_per_line = 60  # Maximum characters per line for readability
        
        for line in raw_lines:
            if len(line) > max_chars_per_line:
                # Find a good breaking point near the middle
                mid_point = max_chars_per_line
                
                # Look for a space to break at
                while mid_point > max_chars_per_line // 2 and line[mid_point] != ' ':
                    mid_point -= 1
                
                if mid_point <= max_chars_per_line // 2:
                    # If we couldn't find a good breaking point, just use max length
                    poem_lines.append(line[:max_chars_per_line])
                    poem_lines.append(line[max_chars_per_line:])
                else:
                    # Break at the space
                    poem_lines.append(line[:mid_point])
                    poem_lines.append(line[mid_point+1:])  # Skip the space
            else:
                poem_lines.append(line)
        
        # Count lines for spacing calculation
        line_count = len(poem_lines)
        
        # First, determine image height maintaining aspect ratio
        image_area_height = int(original_height * (target_width / original_width))
        
        # New rule: Adjust the image ratio based on poem length
        # For longer poems, give more space to the text section
        if line_count <= 4:
            # Default ratio for short poems - image takes 70%
            target_image_ratio = 0.70
        elif line_count <= 8:
            # Medium length poems - image takes 65%
            target_image_ratio = 0.65
        else:
            # Long poems - image takes 60%
            target_image_ratio = 0.60
            
        # Calculate total height based on the image height and the adjusted ratio
        total_height = int(image_area_height / target_image_ratio)
        
        # Text section is the remaining portion of the total height
        text_section_height = int(total_height * (1 - target_image_ratio))
        
        # Calculate font size based on the 30% text area and number of lines
        # This ensures the text will properly fit in the allocated space
        if line_count > 0:
            # Calculate available height for text block (minus some padding)
            available_text_height = text_section_height * 0.9  # Use 90% of the text section
            
            # We'll use a more consistent approach for font size calculations
            # so we don't need this variable anymore
            
            # Scale by width - with a consistent font size across all lines
            base_font_size = target_width * 0.05
            
            # Use the available height to adjust font size based on number of lines
            height_based_font_size = available_text_height / (line_count * 1.3)
            
            # Combine both approaches to get the optimal font size
            poem_font_size = min(int(base_font_size), int(height_based_font_size))
            
            # Ensure a minimum readable size
            poem_font_size = max(18, poem_font_size)
            
            # With the new adaptive image ratio, we can keep font sizes more consistent
            # Apply only minor reductions for very long poems
            if line_count > 10:
                poem_font_size = int(poem_font_size * 0.85)
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
        
        # Draw each line of the poem with center alignment
        for i, line in enumerate(poem_lines):
            # Calculate text width for centering
            try:
                line_width = draw.textlength(line, font=font)
            except:
                # For older PIL versions that don't have textlength
                try:
                    line_width = font.getmask(line).getbbox()[2]
                except:
                    # Approximate width if all else fails
                    line_width = len(line) * (poem_font_size * 0.6)
                    
            # Always center align all text for each line individually
            # This ensures perfect centering regardless of line length
            text_x = (target_width - line_width) // 2
            
            # Ensure text doesn't get too close to edges (minimum side margin)
            min_side_margin = int(target_width * 0.1)  # 10% minimum margin on each side
            if text_x < min_side_margin:
                text_x = min_side_margin
                
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
                # With our new adaptive image size approach, we can display all text
                # without truncation since we've allocated more space for longer poems
                draw.text((text_x, line_y), line, fill=(0, 0, 0), font=font)
        
        # Save the final image with high quality
        output = io.BytesIO()
        final_img.save(output, format="JPEG", quality=95)
        
        # Get the image data
        result = output.getvalue()
        
        # Store in cache for future use
        IMAGE_CACHE[key] = result
        logger.info(f"Stored framed image in cache with key: {key[:8]}...")
        
        # Check if we need to trim the cache
        trim_cache()
        
        return result
    
    except Exception as e:
        logger.error(f"Error creating final image: {str(e)}")
        # Return the original image if there's an error
        return image_bytes