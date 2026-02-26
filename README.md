# BassPro Player

A professional Android music player with advanced equalizer built with Flutter.

## Features

- Local music library management with MediaStore integration
- Online streaming support for internet radio and podcasts
- Professional 10-band equalizer with bass enhancement
- Anti-clipping limiter protection
- Background playback with notification controls
- Playlist management with smart playlists
- French UI localization
- Dark and light themes

## Project Structure

```
lib/
├── core/               # Core utilities and constants
│   ├── constants/
│   ├── utils/
│   ├── errors/
│   └── localization/
├── data/               # Data layer
│   ├── models/
│   ├── repositories/
│   ├── datasources/
│   └── services/
├── domain/             # Business logic layer
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/       # UI layer
    ├── providers/
    ├── screens/
    └── widgets/
```

## Requirements

- Flutter SDK: 3.0.0 or higher
- Android SDK: API 21 (Android 5.0) or higher
- Target SDK: API 34 (Android 14)

## Setup

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Connect an Android device or start an emulator
4. Run `flutter run` to start the app

## Dependencies

- **audio_service**: Background audio playback
- **just_audio**: Audio playback and streaming
- **sqflite**: Local database
- **flutter_riverpod**: State management
- **permission_handler**: Android permissions

## Build

### Debug Build
```bash
flutter run
```

### Release Build
```bash
flutter build apk --release
```

## License

Copyright © 2024 BassPro Player
