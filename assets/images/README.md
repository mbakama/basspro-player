# BassPro Player - Image Assets

This directory contains image assets used throughout the app, including splash screen branding and placeholder images.

## Files

### Splash Screen Assets

#### splash_branding.png
The branding image displayed at the bottom of the splash screen showing "BassPro Player" in the app's primary purple color (#BB86FC).

**Specifications**:
- Dimensions: 800x200px
- Format: PNG with transparency
- Text: "BassPro Player"
- Color: #BB86FC (primary purple)
- Background: Transparent

### create_splash_branding.py
Python script to generate the splash_branding.png image.

**Usage**:
```bash
python create_splash_branding.py
```

**Requirements**:
- Python 3.x
- Pillow (PIL) library: `pip install pillow`

### Placeholder Images

#### track_placeholder.png
Placeholder image for tracks without artwork. Features a music note icon in the app's primary purple color on a dark surface background.

**Specifications**:
- Dimensions: 300x300px
- Format: PNG
- Icon: Music note (eighth note)
- Primary Color: #BB86FC (purple)
- Accent Color: #03DAC6 (teal)
- Background: #1E1E1E (dark surface)

**Usage in Flutter**:
```dart
Image.asset(
  'assets/images/track_placeholder.png',
  width: 48,
  height: 48,
  fit: BoxFit.cover,
)
```

#### stream_placeholder.png
Placeholder image for streaming sources without artwork. Features a radio wave/broadcast icon in the app's secondary teal color on a dark surface background.

**Specifications**:
- Dimensions: 300x300px
- Format: PNG
- Icon: Radio waves with antenna
- Primary Color: #03DAC6 (teal)
- Accent Color: #BB86FC (purple)
- Background: #1E1E1E (dark surface)

**Usage in Flutter**:
```dart
Image.asset(
  'assets/images/stream_placeholder.png',
  width: 48,
  height: 48,
  fit: BoxFit.cover,
)
```

#### create_placeholders.py
Python script to generate both placeholder images (track_placeholder.png and stream_placeholder.png).

**Usage**:
```bash
python create_placeholders.py
```

**Requirements**:
- Python 3.x
- Pillow (PIL) library: `pip install pillow`

## Regenerating Assets

### Splash Screen

After modifying any splash screen assets, regenerate the splash screen resources:

```bash
cd basspro_player
dart run flutter_native_splash:create
```

This will update all Android splash screen resources in `android/app/src/main/res/`.

### Placeholder Images

To regenerate placeholder images:

```bash
cd assets/images
python create_placeholders.py
```

The placeholders are designed to work well at various sizes (48x48 for thumbnails, 300x300 for large displays).

## Customization

### Splash Screen Branding

To customize the branding text:

1. Edit `create_splash_branding.py`
2. Modify the `app_name` variable
3. Optionally adjust colors, dimensions, or font
4. Run the script: `python create_splash_branding.py`
5. Regenerate splash screen: `dart run flutter_native_splash:create`

### Placeholder Images

To customize placeholder designs:

1. Edit `create_placeholders.py`
2. Modify the drawing code in `create_track_placeholder()` or `create_stream_placeholder()`
3. Optionally adjust colors, sizes, or icons
4. Run the script: `python create_placeholders.py`
5. The new images will be automatically used by the app (no rebuild needed)

## Related Files

- **Splash Configuration**: `pubspec.yaml` (flutter_native_splash section)
- **App Icon**: `assets/icon/app_icon.png` (used as splash screen icon)
- **Asset Configuration**: `pubspec.yaml` (flutter assets section)
- **Documentation**: 
  - `TASK_35.1_APP_ICON.md` (app icon implementation)
  - `TASK_35.2_SPLASH_SCREEN.md` (splash screen implementation)
  - `TASK_35.3_PLACEHOLDERS.md` (placeholder images implementation)

## Design Guidelines

All images follow the BassPro Player design system:

**Color Palette**:
- Primary Purple: #BB86FC
- Secondary Teal: #03DAC6
- Dark Background: #121212
- Dark Surface: #1E1E1E

**Design Principles**:
- Simple, recognizable icons
- Consistent color usage
- Works well at multiple sizes
- Matches app's dark theme aesthetic
- Professional appearance

## See Also

- [flutter_native_splash package](https://pub.dev/packages/flutter_native_splash)
- [Android Splash Screens](https://developer.android.com/develop/ui/views/launch/splash-screen)
- BassPro Player Icon Design: `assets/icon/ICON_DESIGN.md`
