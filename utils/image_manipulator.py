import io
import logging
import os
import hashlib
from PIL import Image, ImageDraw, ImageFont, ImageOps

# Set up logging
logger = logging.getLogger(__name__)

# Cache for framed images to improve performance
IMAGE_CACHE = {}
MAX_CACHE_SIZE = 50


def trim_cache():
    """Remove oldest entries from cache if it exceeds the maximum size."""
    global IMAGE_CACHE
    if len(IMAGE_CACHE) > MAX_CACHE_SIZE:
        keys_to_remove = list(IMAGE_CACHE.keys())[:(len(IMAGE_CACHE) -
                                                    MAX_CACHE_SIZE)]
        for key in keys_to_remove:
            del IMAGE_CACHE[key]


def wrap_text(line, font, max_width):
    """Improved text wrapping that handles long words more naturally."""
    words = line.split()
    lines = []
    current_line = []

    for word in words:
        # Test if adding the word would exceed the width
        test_line = ' '.join(current_line + [word])
        test_width = font.getlength(test_line)

        if test_width <= max_width:
            current_line.append(word)
        else:
            # If current line is not empty, finalize it
            if current_line:
                lines.append(' '.join(current_line))
                current_line = []

            # Handle very long words (longer than max_width)
            word_width = font.getlength(word)
            if word_width > max_width:
                # Try to break at hyphens or slashes if present
                if '-' in word:
                    parts = word.split('-')
                    for i, part in enumerate(parts):
                        if i != len(parts) - 1:
                            part += '-'
                        if current_line:
                            test_line = ' '.join(current_line + [part])
                        else:
                            test_line = part
                        if font.getlength(test_line) <= max_width:
                            current_line.append(part)
                        else:
                            if current_line:
                                lines.append(' '.join(current_line))
                            lines.append(part)
                            current_line = []
                    continue

                # If no hyphens, break the word at max_width
                broken = []
                current_part = ''
                for char in word:
                    if font.getlength(current_part + char) <= max_width:
                        current_part += char
                    else:
                        if current_part:
                            broken.append(current_part)
                        current_part = char
                if current_part:
                    broken.append(current_part)
                lines.extend(broken)
            else:
                current_line.append(word)

    if current_line:
        lines.append(' '.join(current_line))

    return lines


def break_long_word(word, font, max_width):
    """Break a single word that's too long into smaller parts."""
    parts = []
    current = ""
    for char in word:
        test = current + char
        if font.getlength(test) > max_width:
            if current:
                parts.append(current)
            current = char
        else:
            current = test
    if current:
        parts.append(current)
    return parts


def create_framed_image(image_bytes, poem_text):
    """Create an image with properly formatted poem text below it."""
    # Create cache key
    cache_key = hashlib.blake2b(digest_size=16)
    cache_key.update(image_bytes)
    cache_key.update(poem_text.encode('utf-8'))
    key = cache_key.hexdigest()

    if key in IMAGE_CACHE:
        logger.info(f"Using cached framed image for key: {key[:8]}...")
        return IMAGE_CACHE[key]

    try:
        # Load and resize image
        img = Image.open(io.BytesIO(image_bytes))
        # Fix orientation based on EXIF data
        img = ImageOps.exif_transpose(img)
        original_width, original_height = img.size
        target_width = min(original_width, 1000)
        image_margin = 20
        image_width_with_margin = target_width - 2 * image_margin
        image_height_with_margin = int(
            original_height * (image_width_with_margin / original_width))
        img_resized = img.resize(
            (image_width_with_margin, image_height_with_margin), Image.LANCZOS)

        # Process poem text
        raw_lines = [
            line for line in poem_text.strip().split("\n") if line.strip()
        ]

        # Initial font setup
        base_font_size = min(int(target_width * 0.045), 32)
        poem_font_size = base_font_size

        # Try to find a suitable font
        font_paths = [
            "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf", "Georgia.ttf",
            "times.ttf", "Times New Roman.ttf", "DejaVuSerif.ttf",
            "LiberationSerif-Regular.ttf"
        ]

        font = None
        for font_path in font_paths:
            try:
                font = ImageFont.truetype(font_path, size=poem_font_size)
                break
            except:
                continue
        if font is None:
            font = ImageFont.load_default()
            logger.warning("Using default font")

        # Calculate text dimensions
        min_side_margin = int(target_width * 0.08)
        max_text_width = target_width - (2 * min_side_margin)

        # Wrap all text lines
        wrapped_lines = []
        for line in raw_lines:
            wrapped_lines.extend(wrap_text(line, font, max_text_width))
        line_count = len(wrapped_lines)

        # Calculate heights
        test_bbox = font.getbbox("Mg")
        font_height = test_bbox[3] - test_bbox[1]
        poem_line_height = int(font_height * 1.5)
        total_text_height = line_count * poem_line_height

        # Image area calculations
        image_area_height = image_height_with_margin + 2 * image_margin
        separator_height = 2
        min_text_area = total_text_height + (poem_font_size * 2)
        total_height = image_area_height + min_text_area

        # Create final image without frame
        final_img = Image.new("RGB", (target_width, total_height),
                              (255, 255, 255))
        final_img.paste(img_resized, (image_margin, image_margin))

        draw = ImageDraw.Draw(final_img)

        # Draw separator
        draw.rectangle([(image_margin, image_area_height - image_margin),
                        (target_width - image_margin,
                         image_area_height - image_margin + separator_height)],
                       fill=(240, 240, 240))

        # Adjust font size if needed
        available_text_height = final_img.height - image_area_height
        while (total_text_height > available_text_height) and (poem_font_size
                                                               > 12):
            poem_font_size -= 1
            font = ImageFont.truetype(font.path, poem_font_size) if hasattr(
                font, 'path') else ImageFont.load_default()
            test_bbox = font.getbbox("Mg")
            font_height = test_bbox[3] - test_bbox[1]
            poem_line_height = int(font_height * 1.5)
            total_text_height = line_count * poem_line_height

        # Position and draw text
        text_y = image_area_height + (available_text_height -
                                      total_text_height) // 2
        for i, line in enumerate(wrapped_lines):
            bbox = font.getbbox(line)
            line_width = bbox[2] - bbox[0]
            text_x = (target_width - line_width) // 2
            text_x = max(
                min_side_margin,
                min(text_x, target_width - line_width - min_side_margin))

            line_y = text_y + (i * poem_line_height)

            # Draw with subtle shadow for readability
            if str(font) != str(ImageFont.load_default()):
                draw.text((text_x + 1, line_y + 1),
                          line,
                          fill=(200, 200, 200),
                          font=font)
            draw.text((text_x, line_y), line, fill=(0, 0, 0), font=font)

        # Save and cache
        output = io.BytesIO()
        final_img.save(output, format="JPEG", quality=95)
        result = output.getvalue()
        IMAGE_CACHE[key] = result
        trim_cache()

        return result

    except Exception as e:
        logger.error(f"Error creating final image: {str(e)}", exc_info=True)
        return image_bytes
