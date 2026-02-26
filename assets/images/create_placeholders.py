#!/usr/bin/env python3
"""
Generate placeholder images for BassPro Player

Creates two placeholder images:
1. track_placeholder.png - For tracks without artwork (music note icon)
2. stream_placeholder.png - For streaming sources (radio wave icon)

Both use the app's color scheme and work well at various sizes (48x48 to 300x300).
"""

from PIL import Image, ImageDraw
import math

# App color scheme (from app_theme.dart)
DARK_SURFACE = (30, 30, 30)  # #1E1E1E
PRIMARY_COLOR = (187, 134, 252)  # #BB86FC (purple)
SECONDARY_COLOR = (3, 218, 198)  # #03DAC6 (teal)
DARK_BACKGROUND = (18, 18, 18)  # #121212

# Image size (square, works well at all sizes)
SIZE = 300


def create_track_placeholder():
    """
    Create placeholder for tracks without artwork.
    Features a music note icon on dark surface background.
    """
    img = Image.new('RGB', (SIZE, SIZE), DARK_SURFACE)
    draw = ImageDraw.Draw(img)
    
    # Calculate dimensions
    center_x = SIZE // 2
    center_y = SIZE // 2
    
    # Music note design (simplified eighth note)
    # Scale factor for sizing
    scale = SIZE / 300
    
    # Note head (circle)
    note_head_radius = int(30 * scale)
    note_head_x = center_x - int(20 * scale)
    note_head_y = center_y + int(40 * scale)
    
    # Draw note head (filled circle)
    draw.ellipse(
        [
            note_head_x - note_head_radius,
            note_head_y - note_head_radius,
            note_head_x + note_head_radius,
            note_head_y + note_head_radius
        ],
        fill=PRIMARY_COLOR
    )
    
    # Note stem (vertical line)
    stem_width = int(8 * scale)
    stem_height = int(100 * scale)
    stem_x = note_head_x + note_head_radius - stem_width // 2
    stem_y = note_head_y - stem_height
    
    draw.rectangle(
        [stem_x, stem_y, stem_x + stem_width, note_head_y],
        fill=PRIMARY_COLOR
    )
    
    # Note flag (curved flag at top of stem)
    flag_width = int(40 * scale)
    flag_height = int(50 * scale)
    
    # Draw flag as a series of curves
    for i in range(3):
        offset = i * int(15 * scale)
        draw.arc(
            [
                stem_x + stem_width,
                stem_y + offset,
                stem_x + stem_width + flag_width,
                stem_y + offset + flag_height
            ],
            start=270,
            end=90,
            fill=PRIMARY_COLOR,
            width=int(8 * scale)
        )
    
    # Add subtle gradient effect with secondary color accent
    # Small circle accent in top right
    accent_size = int(15 * scale)
    accent_x = center_x + int(60 * scale)
    accent_y = center_y - int(60 * scale)
    
    draw.ellipse(
        [
            accent_x - accent_size,
            accent_y - accent_size,
            accent_x + accent_size,
            accent_y + accent_size
        ],
        fill=SECONDARY_COLOR
    )
    
    return img


def create_stream_placeholder():
    """
    Create placeholder for streaming sources.
    Features radio wave/broadcast icon on dark surface background.
    """
    img = Image.new('RGB', (SIZE, SIZE), DARK_SURFACE)
    draw = ImageDraw.Draw(img)
    
    # Calculate dimensions
    center_x = SIZE // 2
    center_y = SIZE // 2
    scale = SIZE / 300
    
    # Central dot (broadcast source)
    dot_radius = int(15 * scale)
    draw.ellipse(
        [
            center_x - dot_radius,
            center_y - dot_radius,
            center_x + dot_radius,
            center_y + dot_radius
        ],
        fill=SECONDARY_COLOR
    )
    
    # Radio waves (concentric arcs)
    wave_colors = [PRIMARY_COLOR, SECONDARY_COLOR, PRIMARY_COLOR]
    wave_widths = [int(8 * scale), int(6 * scale), int(4 * scale)]
    
    for i, (color, width) in enumerate(zip(wave_colors, wave_widths)):
        radius = int((40 + i * 35) * scale)
        
        # Left arc
        draw.arc(
            [
                center_x - radius,
                center_y - radius,
                center_x + radius,
                center_y + radius
            ],
            start=135,
            end=225,
            fill=color,
            width=width
        )
        
        # Right arc
        draw.arc(
            [
                center_x - radius,
                center_y - radius,
                center_x + radius,
                center_y + radius
            ],
            start=315,
            end=45,
            fill=color,
            width=width
        )
    
    # Add small antenna/tower at bottom
    tower_width = int(6 * scale)
    tower_height = int(30 * scale)
    tower_x = center_x - tower_width // 2
    tower_y = center_y + dot_radius
    
    draw.rectangle(
        [tower_x, tower_y, tower_x + tower_width, tower_y + tower_height],
        fill=SECONDARY_COLOR
    )
    
    # Tower base (small triangle)
    base_width = int(20 * scale)
    base_height = int(10 * scale)
    base_y = tower_y + tower_height
    
    draw.polygon(
        [
            (center_x, base_y),
            (center_x - base_width // 2, base_y + base_height),
            (center_x + base_width // 2, base_y + base_height)
        ],
        fill=SECONDARY_COLOR
    )
    
    return img


def main():
    """Generate both placeholder images."""
    print("Generating placeholder images for BassPro Player...")
    
    # Create track placeholder
    print("Creating track_placeholder.png...")
    track_img = create_track_placeholder()
    track_img.save('track_placeholder.png', 'PNG')
    print(f"✓ Saved track_placeholder.png ({SIZE}x{SIZE})")
    
    # Create stream placeholder
    print("Creating stream_placeholder.png...")
    stream_img = create_stream_placeholder()
    stream_img.save('stream_placeholder.png', 'PNG')
    print(f"✓ Saved stream_placeholder.png ({SIZE}x{SIZE})")
    
    print("\nPlaceholder images generated successfully!")
    print("\nUsage in Flutter:")
    print("  - Track placeholder: Image.asset('assets/images/track_placeholder.png')")
    print("  - Stream placeholder: Image.asset('assets/images/stream_placeholder.png')")


if __name__ == '__main__':
    main()
