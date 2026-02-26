# BassPro Player Icon Generation

## Quick Start

This directory contains the icon design for BassPro Player. Follow one of the methods below to generate the app icons.

## Method 1: Automated Generation (Recommended)

### Prerequisites
```bash
pip install cairosvg pillow
```

### Generate Icons
```bash
cd basspro_player/assets/icon
python generate_icons.py
```

This will automatically create all required icon sizes in the Android resource directories.

## Method 2: Using Flutter Launcher Icons Package

### 1. Add the package to pubspec.yaml
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

### 2. Add configuration to pubspec.yaml
```yaml
flutter_launcher_icons:
  android: true
  image_path: "assets/icon/app_icon_512.png"
  adaptive_icon_background: "#6200EE"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

### 3. Run the generator
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## Method 3: Manual Export from SVG

Use any SVG editor (Inkscape, Illustrator, Figma) to export `app_icon.svg` at these sizes:

- 48x48px → android/app/src/main/res/mipmap-mdpi/ic_launcher.png
- 72x72px → android/app/src/main/res/mipmap-hdpi/ic_launcher.png
- 96x96px → android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
- 144x144px → android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
- 192x192px → android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

## Method 4: Online Icon Generator

1. Go to https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html
2. Upload the `app_icon.svg` or `app_icon_512.png` file
3. Adjust settings as needed
4. Download the generated icon pack
5. Extract and copy the mipmap-* folders to `android/app/src/main/res/`

## Icon Design

See [ICON_DESIGN.md](ICON_DESIGN.md) for detailed information about the icon design, colors, and rationale.

## Verification

After generating the icons, verify they were created:

```bash
# Check if all icon files exist
ls -la ../../android/app/src/main/res/mipmap-*/ic_launcher.png
```

You should see 5 files (one for each density: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi).

## Testing

Build and install the app to see the new icon:

```bash
cd ../..  # Return to basspro_player directory
flutter build apk
flutter install
```

The new icon should appear on your device's home screen and app drawer.
