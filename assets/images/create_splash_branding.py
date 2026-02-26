#!/usr/bin/env python3
"""
Generate splash screen branding image for BassPro Player.

This script creates a simple text-based branding image with the app name
"BassPro Player" in the app's primary color on a transparent background.
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_splash_branding():
    """Create the splash screen branding image."""
    
    # Image dimensions (width x height)
    width = 800
    height = 200
    
    # Create image with transparent background
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # App name
    app_name = "BassPro Player"
    
    # Primary color from app theme (purple)
    text_color = (187, 134, 252, 255)  # #BB86FC
    
    # Try to use a nice font, fall back to default if not available
    try:
        # Try to load a system font
        font_size = 72
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
    except:
        try:
            # Try Windows font
            font = ImageFont.truetype("C:\\Windows\\Fonts\\Arial.ttf", 72)
        except:
            # Fall back to default font
            font = ImageFont.load_default()
    
    # Get text bounding box to center it
    bbox = draw.textbbox((0, 0), app_name, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Calculate position to center text
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    
    # Draw the text
    draw.text((x, y), app_name, fill=text_color, font=font)
    
    # Save the image
    output_path = os.path.join(os.path.dirname(__file__), 'splash_branding.png')
    img.save(output_path, 'PNG')
    print(f"✓ Created splash branding image: {output_path}")
    print(f"  Dimensions: {width}x{height}px")
    print(f"  Text: '{app_name}'")
    print(f"  Color: #{text_color[0]:02x}{text_color[1]:02x}{text_color[2]:02x}")

if __name__ == '__main__':
    create_splash_branding()
