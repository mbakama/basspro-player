# Changelog

All notable changes to BassPro Player will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-XX

### Initial Release

BassPro Player 1.0.0 is the first public release of this professional Android music player with advanced equalizer capabilities.

#### Added

**Local Music Library**
- Automatic music discovery using Android MediaStore API
- Browse music by Songs, Artists, and Albums
- Real-time search across title, artist, and album fields
- Multiple sorting options: Title, Artist, Album, Date Added, Duration
- Favorites system with one-tap marking
- Play statistics tracking (play count, last played timestamp)
- Smart playlists: Favorites, Recently Added, Most Played
- Library rescan functionality to detect new or removed files
- Support for Android 10+ scoped storage

**Online Streaming**
- Add unlimited streaming sources (internet radio, podcasts)
- Stream source management: add, edit, delete, favorite
- Recently played streams history
- Category organization for streams
- Automatic retry with exponential backoff for failed connections
- Network error handling with user-friendly messages
- Buffering indicators during stream loading

**Professional Equalizer**
- 10-band frequency equalizer (32Hz, 64Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz)
- Preamp gain control (-10dB to +10dB)
- Dedicated Sub-bass boost control (below 60Hz)
- Dedicated Bass boost control (60Hz-250Hz)
- Built-in limiter for anti-clipping protection
- Real-time audio processing during playback
- Clipping risk detection with visual warnings
- 8 built-in presets:
  - Deep Bass: Maximum sub-bass emphasis
  - Punch Bass: Powerful mid-bass punch
  - Hip-Hop: Optimized for hip-hop and rap
  - EDM: Electronic dance music profile
  - Rock: Rock and metal emphasis
  - Pop: Balanced pop music profile
  - Vocal Clarity: Enhanced vocal frequencies
  - Balanced: Flat response (no adjustments)
- Custom preset creation and management
- Preset persistence across app restarts
- Equalizer settings apply to both local and streaming playback

**Playlist Management**
- Create unlimited custom playlists
- Add tracks to multiple playlists
- Drag-to-reorder tracks within playlists
- Swipe-to-delete tracks from playlists
- Rename and delete playlists
- Play entire playlists with one tap
- Smart playlists automatically update based on criteria

**Playback Controls**
- Full playback controls: Play, Pause, Next, Previous
- Seek bar with precise position control
- Shuffle mode with queue randomization
- Repeat modes: Off, Repeat All, Repeat One
- Playback queue management
- Add to queue functionality
- Reorder queue by dragging
- Clear queue option
- Current position and total duration display

**Background Playback**
- Seamless background playback when app is minimized
- Notification controls: Play, Pause, Next, Previous
- Lock screen media controls with artwork
- Media button support (headphones, Bluetooth devices)
- Audio focus handling:
  - Pause on incoming phone calls
  - Duck volume for notifications
  - Resume after interruptions
- Foreground service for reliable background operation

**User Interface**
- Modern Material Design interface
- Dark theme (default) with deep blacks for OLED displays
- Light theme option
- French localization for all UI elements
- Mini player for quick access from any screen
- Full-screen Now Playing interface with large artwork
- Modal equalizer screen with intuitive controls
- Smooth animations and transitions (300-400ms)
- Swipe gestures: down to dismiss, left/right to skip tracks
- Bottom navigation: Library, Streaming, Playlists, Settings
- Search functionality with real-time filtering
- Context menus for quick actions

**Settings & Preferences**
- Theme selection (Dark/Light)
- Default equalizer preset selection
- Sleep timer: 15, 30, 45, 60, 90 minutes
- Keep screen awake during playback option
- Library rescan trigger
- All preferences persist across app restarts

**Performance Optimizations**
- Smooth 60fps scrolling with large libraries (10,000+ tracks)
- Artwork caching (memory + disk) with LRU eviction
- Lazy loading for artwork as user scrolls
- Database query optimization with indexes
- Query result caching for frequently accessed data
- Fast app startup (< 2 seconds to library display)
- Efficient memory usage (< 150MB typical)
- Battery-friendly background playback

**Error Handling**
- Comprehensive error handling for all operations
- User-friendly error messages in French
- Automatic retry for network failures
- Graceful degradation when features unavailable
- Error recovery mechanisms:
  - Retry buttons for failed operations
  - Skip to next track on playback failure
  - Library rescan for missing files
  - Connection error notifications

**Technical Features**
- Clean Architecture (data/domain/presentation layers)
- Riverpod state management
- SQLite database with optimized schema
- Comprehensive test suite (unit, integration, widget tests)
- Property-based testing for correctness validation
- ProGuard/R8 code shrinking and obfuscation
- Signed release builds with keystore
- Support for Android 5.0 (API 21) through Android 14 (API 34)

#### Technical Details

**Supported Audio Formats**
- MP3 (MPEG Audio Layer 3)
- M4A (MPEG-4 Audio)
- AAC (Advanced Audio Coding)
- FLAC (Free Lossless Audio Codec)
- WAV (Waveform Audio File Format)
- OGG (Ogg Vorbis)
- OPUS (Opus Interactive Audio Codec)

**Supported Streaming Protocols**
- HTTP/HTTPS audio streams
- Icecast/Shoutcast streams
- Direct audio file URLs

**Android Versions**
- Minimum: Android 5.0 (API 21)
- Target: Android 14 (API 34)
- Tested on: Android 5.0, 8.0, 10, 12, 14

**Permissions Required**
- `READ_EXTERNAL_STORAGE`: Access music files (Android 9 and below)
- `INTERNET`: Stream online audio
- `FOREGROUND_SERVICE`: Background playback
- `WAKE_LOCK`: Keep device awake during playback
- `MEDIA_CONTENT_CONTROL`: Media button handling

**Dependencies**
- Flutter SDK: 3.0.0+
- audio_service: ^0.18.12
- just_audio: ^0.9.36
- sqflite: ^2.3.0
- flutter_riverpod: ^2.4.9
- permission_handler: ^11.0.1
- wakelock_plus: ^1.2.8

#### Known Limitations

- No gapless playback between tracks
- No crossfade support
- No lyrics display
- No Android Auto integration
- No Chromecast support
- Streaming sources requiring authentication not supported
- No cloud sync for playlists
- No Last.fm scrobbling

#### Installation Notes

**First Launch**
1. Grant storage permission when prompted
2. Wait for initial library scan to complete
3. Explore your music library in the Library tab
4. Adjust equalizer to your preference
5. Create playlists and enjoy!

**Upgrading from Beta**
- This is the first stable release
- No beta versions were publicly released

#### Build Information

- **Version Name**: 1.0.0
- **Version Code**: 1
- **Build Type**: Release
- **Min SDK**: 21
- **Target SDK**: 34
- **Compile SDK**: 34
- **APK Size**: ~20-25 MB (varies by architecture)
- **App Bundle Size**: ~18-22 MB

#### Credits

**Development Team**
- BassPro Player Development Team

**Open Source Libraries**
- audio_service by Ryan Heise
- just_audio by Ryan Heise
- sqflite by Tekartik
- flutter_riverpod by Remi Rousselet
- permission_handler by Baseflow
- And many other Flutter community packages

#### Support

For issues, questions, or feature requests:
- GitHub Issues: [repository-url]/issues
- Email: support@bassplayer.example.com

#### License

BassPro Player is released under the MIT License.

---

## [Unreleased]

### Planned Features

Features under consideration for future releases:

- Gapless playback
- Crossfade between tracks
- Lyrics display with synchronization
- Audio effects (reverb, echo, pitch shift)
- Podcast support with chapter navigation
- Android Auto integration
- Chromecast support
- Cloud sync for playlists and settings
- Last.fm scrobbling
- Audio visualizer
- Gesture controls customization
- Folder browsing
- Tag editor
- Sleep timer fade out
- Equalizer presets import/export
- Backup and restore functionality

---

## Version History

### Version Numbering

BassPro Player follows Semantic Versioning (SemVer):

- **Major version** (X.0.0): Breaking changes, major new features
- **Minor version** (0.X.0): New features, backward compatible
- **Patch version** (0.0.X): Bug fixes, minor improvements

### Release Schedule

- **Major releases**: Annually or when significant features are ready
- **Minor releases**: Quarterly or when new features are complete
- **Patch releases**: As needed for bug fixes and improvements

---

**Note**: This changelog will be updated with each release. Check back for the latest changes and improvements.

[1.0.0]: https://github.com/username/basspro_player/releases/tag/v1.0.0
[Unreleased]: https://github.com/username/basspro_player/compare/v1.0.0...HEAD
