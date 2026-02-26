#!/usr/bin/env python3
"""
Icon Generator for BassPro Player
Generates Android launcher icons at all required densities from SVG source.

Requirements:
    pip install cairosvg pillow

Usage:
    python generate_icons.py
"""

import os
from pathlib import Path

try:
    import cairosvg
    from PIL import Image
    import io
except ImportError:
    print("Error: Required packages not installed.")
    print("Please run: pip install cairosvg pillow")
    exit(1)

# Icon sizes for different Android densities
ICON_SIZES = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}

def generate_png_from_svg(svg_path, output_path, size):
    """Convert SVG to PNG at specified size."""
    print(f"Generating {output_path} at {size}x{size}...")
    
    # Convert SVG to PNG using cairosvg
    png_data = cairosvg.svg2png(
        url=str(svg_path),
        output_width=size,
        output_height=size
    )
    
    # Open with PIL and save
    img = Image.open(io.BytesIO(png_data))
    img.save(output_path, 'PNG', optimize=True)
    print(f"✓ Created {output_path}")

def main():
    # Get paths
    script_dir = Path(__file__).parent
    svg_path = script_dir / 'app_icon.svg'
    android_res_dir = script_dir.parent.parent / 'android' / 'app' / 'src' / 'main' / 'res'
    
    if not svg_path.exists():
        print(f"Error: SVG file not found at {svg_path}")
        exit(1)
    
    if not android_res_dir.exists():
        print(f"Error: Android res directory not found at {android_res_dir}")
        exit(1)
    
    print("BassPro Player Icon Generator")
    print("=" * 50)
    print(f"Source SVG: {svg_path}")
    print(f"Output directory: {android_res_dir}")
    print()
    
    # Generate icons for each density
    for density, size in ICON_SIZES.items():
        mipmap_dir = android_res_dir / f'mipmap-{density}'
        mipmap_dir.mkdir(parents=True, exist_ok=True)
        
        output_path = mipmap_dir / 'ic_launcher.png'
        generate_png_from_svg(svg_path, output_path, size)
    
    print()
    print("=" * 50)
    print("✓ All icons generated successfully!")
    print()
    print("Icon sizes created:")
    for density, size in ICON_SIZES.items():
        print(f"  - mipmap-{density}/ic_launcher.png ({size}x{size})")
    print()
    print("The AndroidManifest.xml is already configured to use these icons.")
    print("You can now build and run the app to see the new icon.")

if __name__ == '__main__':
    main()
