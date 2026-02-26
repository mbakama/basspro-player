# Android Platform Integration

This document describes the Android platform-specific code for BassPro Player.

## Overview

The Android platform integration provides:
1. MediaStore access for scanning local audio files
2. Background audio service configuration
3. Media button receiver for headphone/Bluetooth controls

## Components

### 1. MainActivity.kt

**Location**: `android/app/src/main/kotlin/com/example/basspro_player/MainActivity.kt`

**Purpose**: Provides a MethodChannel bridge between Flutter and Android MediaStore API.

**Features**:
- Queries Android MediaStore for audio files
- Retrieves metadata: title, artist, album, duration, URIs, artwork
- Filters for music files only (excludes notifications, ringtones)
- Returns data in a format compatible with Flutter

**MethodChannel**: `com.example.basspro_player/mediastore`

**Available Methods**:
- `queryAudioFiles()`: Returns a list of audio files with metadata

**Data Structure**:
```kotlin
{
  "id": Long,              // MediaStore audio ID
  "title": String,         // Track title
  "artist": String,        // Artist name
  "album": String,         // Album name
  "duration": Long,        // Duration in milliseconds
  "uri": String,           // Content URI for playback
  "artworkUri": String,    // Album artwork URI
  "dateAdded": Long        // Date added timestamp (milliseconds)
}
```

### 2. AndroidManifest.xml

**Location**: `android/app/src/main/AndroidManifest.xml`

**Permissions**:
- `READ_EXTERNAL_STORAGE` (maxSdkVersion="32"): For Android 9 and below
- `WAKE_LOCK`: Keep device awake during playback
- `FOREGROUND_SERVICE`: Enable background playback
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK`: Specify media playback service type
- `INTERNET`: For streaming audio
- `ACCESS_NETWORK_STATE`: Check network connectivity

**Audio Service Configuration**:
```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
</service>
```

This service enables:
- Background audio playback
- Notification controls
- Lock screen controls
- Audio focus management

**Media Button Receiver**:
```xml
<receiver
    android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</receiver>
```

This receiver handles:
- Headphone button controls (play/pause/skip)
- Bluetooth device controls
- Media button events from external devices

## Flutter Integration

### MediaStoreScanner

**Location**: `lib/data/datasources/media_store/media_store_scanner.dart`

**Usage**:
```dart
final scanner = MediaStoreScanner();
final audioFiles = await scanner.queryAudioFiles();

for (final file in audioFiles) {
  print('Title: ${file['title']}');
  print('Artist: ${file['artist']}');
  print('URI: ${file['uri']}');
}
```

## Android Version Compatibility

### Android 10+ (API 29+)
- Uses scoped storage
- No READ_EXTERNAL_STORAGE permission required for MediaStore
- Content URIs are used for file access

### Android 9 and below (API 28-)
- Requires READ_EXTERNAL_STORAGE permission
- Permission must be requested at runtime
- Uses legacy storage access

## Requirements Satisfied

This implementation satisfies the following requirements:

- **Requirement 2.1**: Library scanner uses Android MediaStore API
- **Requirement 2.2**: Retrieves complete metadata (title, artist, album, duration, URIs, artwork)
- **Requirement 10.6**: Media button receiver handles headphone/Bluetooth controls
- **Requirement 22.2**: Audio service configured for background playback with audio_service package

## Testing

To test the MediaStore integration:

1. Ensure device has audio files in Music folder
2. Run the app on a physical device or emulator
3. Call `MediaStoreScanner().queryAudioFiles()`
4. Verify returned data contains all expected fields

To test audio service:

1. Play audio in the app
2. Press home button (app goes to background)
3. Verify playback continues
4. Check notification area for playback controls
5. Test media buttons on headphones/Bluetooth device

## Notes

- The MediaStore query filters for `IS_MUSIC != 0` to exclude system sounds
- Album artwork URIs use the standard Android album art content provider
- Date added timestamps are converted from seconds to milliseconds for consistency
- Error handling is implemented with try-catch and PlatformException handling
