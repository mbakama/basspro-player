#!/usr/bin/env python3
"""
Simple Icon Creator for BassPro Player
Creates a basic PNG icon that can be used as a placeholder or starting point.
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("PIL not available. Install with: pip install pillow")

import os
from pathlib import Path

def create_simple_icon(output_path, size=512):
    """Create a simple icon with PIL."""
    if not PIL_AVAILABLE:
        print("Error: PIL (Pillow) is required to generate icons.")
        print("Install it with: pip install pillow")
        return False
    
    # Create image with purple gradient background
    img = Image.new('RGB', (size, size), color='#6200EE')
    draw = ImageDraw.Draw(img)
    
    # Draw circular background
    margin = size // 16
    draw.ellipse([margin, margin, size-margin, size-margin], fill='#6200EE', outline='#BB86FC', width=size//32)
    
    # Draw waveform bars (5 bars)
    bar_width = size // 12
    bar_spacing = size // 16
    center_y = size // 2
    
    # Bar heights (representing audio waveform)
    bar_heights = [
        size // 3,   # Left bar
        size // 2,   # Left-center bar
        size * 2 // 3,  # Center bar (tallest)
        size // 2,   # Right-center bar
        size // 3,   # Right bar
    ]
    
    start_x = size // 4
    for i, height in enumerate(bar_heights):
        x = start_x + i * (bar_width + bar_spacing)
        y = center_y - height // 2
        
        # Draw rounded rectangle (bar)
        draw.rounded_rectangle(
            [x, y, x + bar_width, y + height],
            radius=bar_width // 2,
            fill='#03DAC6'
        )
    
    # Draw play button in center
    play_size = size // 5
    play_x = size // 2 - play_size // 2
    play_y = size // 2 - play_size // 2
    
    # White circle background for play button
    draw.ellipse(
        [play_x, play_y, play_x + play_size, play_y + play_size],
        fill='white'
    )
    
    # Purple play triangle
    triangle_margin = play_size // 4
    triangle_points = [
        (play_x + triangle_margin, play_y + triangle_margin),
        (play_x + triangle_margin, play_y + play_size - triangle_margin),
        (play_x + play_size - triangle_margin, play_y + play_size // 2)
    ]
    draw.polygon(triangle_points, fill='#6200EE')
    
    # Save the image
    img.save(output_path, 'PNG', optimize=True)
    print(f"✓ Created icon: {output_path}")
    return True

def main():
    script_dir = Path(__file__).parent
    output_path = script_dir / 'app_icon.png'
    
    print("BassPro Player Simple Icon Creator")
    print("=" * 50)
    
    if not PIL_AVAILABLE:
        print("\nPIL (Pillow) is not installed.")
        print("To generate the icon automatically, install it with:")
        print("  pip install pillow")
        print("\nAlternatively, you can:")
        print("1. Use the SVG file (app_icon.svg) with an online converter")
        print("2. Create your own 512x512 PNG icon")
        print("3. Use a design tool like Figma or Inkscape")
        return
    
    success = create_simple_icon(output_path, size=512)
    
    if success:
        print("\n✓ Icon created successfully!")
        print(f"\nIcon saved to: {output_path}")
        print("\nNext steps:")
        print("1. Run: flutter pub get")
        print("2. Run: flutter pub run flutter_launcher_icons")
        print("3. This will generate all Android icon sizes automatically")
        print("\nOr use the generate_icons.py script to create icons directly.")

if __name__ == '__main__':
    main()
