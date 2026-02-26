# BassPro Player - Release Build Guide

This document provides instructions for building and signing the BassPro Player app for release distribution.

## Version Information

- **Current Version**: 1.0.0+1
- **Version Name**: 1.0.0
- **Build Number**: 1
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34

## Release Build Configuration

The release build is configured with the following optimizations:

### Code Shrinking and Obfuscation

- **Minification**: Enabled (R8/ProGuard)
- **Resource Shrinking**: Enabled
- **Optimization**: Enabled (proguard-android-optimize.txt)
- **Custom Rules**: `android/app/proguard-rules.pro`

### ProGuard Rules

The app includes custom ProGuard rules to preserve:

1. **Audio Libraries**: audio_service, just_audio, ExoPlayer
2. **Database Models**: All entity classes and serialization methods
3. **Flutter Framework**: Core Flutter classes and plugins
4. **Media Session**: Android media session support
5. **Kotlin**: Coroutines and serialization support

See `android/app/proguard-rules.pro` for complete rules.

## Generating a Release Keystore

### Step 1: Create a Keystore

Run the following command to generate a new keystore:

```bash
keytool -genkey -v -keystore ~/basspro-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias basspro
```

**Important**: You will be prompted for:
- Keystore password (choose a strong password)
- Key password (can be the same as keystore password)
- Your name, organization, city, state, country

**CRITICAL**: Store these passwords securely! You will need them for all future releases.

### Step 2: Store Keystore Information

Create a file `android/key.properties` (this file is gitignored):

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=basspro
storeFile=<path-to-your-keystore-file>
```

Example:
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=basspro
storeFile=/Users/yourname/basspro-release-key.jks
```

### Step 3: Update build.gradle.kts

Update `android/app/build.gradle.kts` to use the keystore:

```kotlin
// Add this before the android block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... existing release config ...
        }
    }
}
```

## Building Release Artifacts

### Prerequisites

1. Ensure Flutter is up to date:
   ```bash
   flutter upgrade
   ```

2. Clean previous builds:
   ```bash
   flutter clean
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

4. Run tests:
   ```bash
   flutter test
   ```

### Build Release APK

To build a release APK for direct distribution:

```bash
flutter build apk --release
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Build Release App Bundle (Recommended for Play Store)

To build an App Bundle for Google Play Store:

```bash
flutter build appbundle --release
```

The App Bundle will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

### Build Split APKs (Smaller Downloads)

To build split APKs per ABI (reduces download size):

```bash
flutter build apk --release --split-per-abi
```

This generates separate APKs for:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

## Testing Release Builds

### Install Release APK on Device

```bash
flutter install --release
```

Or manually:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Test Checklist

Before distributing, verify:

- [ ] App launches successfully
- [ ] Library scanning works
- [ ] Audio playback works (local files)
- [ ] Streaming playback works
- [ ] Background playback continues
- [ ] Notification controls work
- [ ] Lock screen controls work
- [ ] Equalizer adjustments apply
- [ ] Playlists can be created and played
- [ ] Settings persist across restarts
- [ ] Theme switching works
- [ ] Sleep timer functions correctly
- [ ] No crashes or ANRs
- [ ] Performance is smooth (60fps scrolling)
- [ ] Memory usage is reasonable
- [ ] Battery usage is acceptable

### Test on Multiple Devices

Test on devices with:
- Android 5.0 (API 21) - minimum supported version
- Android 8.0 (API 26) - common version
- Android 10 (API 29) - scoped storage changes
- Android 12 (API 31) - splash screen changes
- Android 14 (API 34) - target version

## Verifying ProGuard Configuration

### Check APK Size

Release APK should be significantly smaller than debug:

```bash
# Debug APK (typical: 40-60 MB)
flutter build apk --debug

# Release APK (typical: 15-25 MB)
flutter build apk --release
```

### Analyze APK Contents

Use Android Studio's APK Analyzer:

1. Open Android Studio
2. Build → Analyze APK
3. Select `build/app/outputs/flutter-apk/app-release.apk`
4. Review:
   - DEX file size (should be optimized)
   - Resources (should be shrunk)
   - Native libraries

### Test Obfuscation

Verify that ProGuard rules are working:

1. Install release APK
2. Trigger an error/crash
3. Check logcat output
4. Verify that:
   - Flutter classes are preserved
   - Audio service classes are preserved
   - Database models are preserved
   - Stack traces are readable (line numbers preserved)

## Troubleshooting

### Issue: App crashes on startup

**Cause**: ProGuard may have removed necessary classes

**Solution**: 
1. Check logcat for ClassNotFoundException or MethodNotFoundException
2. Add keep rules for the missing classes in `proguard-rules.pro`
3. Rebuild and test

### Issue: Audio playback doesn't work

**Cause**: Audio service classes may be obfuscated

**Solution**:
1. Verify audio_service and just_audio keep rules are present
2. Add more specific keep rules if needed
3. Test with `--no-shrink` flag to verify:
   ```bash
   flutter build apk --release --no-shrink
   ```

### Issue: Database errors

**Cause**: Database model serialization methods removed

**Solution**:
1. Ensure all entity classes have keep rules
2. Preserve toMap(), fromMap(), and copyWith() methods
3. Add specific keep rules for your entity classes

### Issue: Large APK size

**Cause**: Resources not being shrunk properly

**Solution**:
1. Verify `isShrinkResources = true` in build.gradle.kts
2. Remove unused assets from `assets/` folder
3. Use split APKs per ABI to reduce size

## Security Best Practices

### Keystore Security

1. **Never commit keystore files to version control**
   - Add `*.jks`, `*.keystore`, `key.properties` to `.gitignore`

2. **Store keystore securely**
   - Keep backup in secure location (encrypted drive, password manager)
   - Consider using a hardware security module (HSM) for production

3. **Use strong passwords**
   - Minimum 12 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Different from other passwords

4. **Limit access**
   - Only authorized team members should have keystore access
   - Use separate keystores for different apps

### Code Security

1. **Remove debug logging**
   - ProGuard rules remove Log.d(), Log.v(), Log.i()
   - Keep Log.e() and Log.w() for production error tracking

2. **Obfuscate sensitive code**
   - ProGuard obfuscates class and method names
   - Keep rules only for necessary classes

3. **Validate inputs**
   - Validate all user inputs (URLs, file paths)
   - Sanitize database queries

## Distribution

### Google Play Store

1. Create a Google Play Developer account
2. Create a new app in Play Console
3. Upload the App Bundle (`.aab` file)
4. Complete store listing (description, screenshots, etc.)
5. Set up content rating
6. Set pricing and distribution
7. Submit for review

### Direct Distribution

1. Build release APK
2. Host on your website or file sharing service
3. Provide installation instructions:
   - Enable "Install from Unknown Sources"
   - Download APK
   - Open and install

### F-Droid (Optional)

For open-source distribution:

1. Ensure app is fully open source
2. Submit to F-Droid repository
3. Follow F-Droid submission guidelines

## Version Management

### Updating Version Numbers

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1
#        ^     ^
#        |     |
#        |     +-- Build number (increment for each release)
#        +-------- Version name (semantic versioning)
```

**Semantic Versioning**:
- **Major** (1.x.x): Breaking changes, major new features
- **Minor** (x.1.x): New features, backward compatible
- **Patch** (x.x.1): Bug fixes, minor improvements

**Build Number**:
- Increment for every release to Play Store
- Must be higher than previous release

### Example Version History

- `1.0.0+1` - Initial release
- `1.0.1+2` - Bug fix release
- `1.1.0+3` - New feature release
- `2.0.0+4` - Major update with breaking changes

## Continuous Integration (CI)

### GitHub Actions Example

Create `.github/workflows/release.yml`:

```yaml
name: Release Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v3
        with:
          name: release-bundle
          path: build/app/outputs/bundle/release/app-release.aab
```

## Support and Maintenance

### Monitoring

Consider integrating:
- **Firebase Crashlytics**: Crash reporting
- **Firebase Analytics**: Usage analytics
- **Sentry**: Error tracking

### Updates

Plan for regular updates:
- Security patches
- Bug fixes
- New features
- Android version compatibility

### User Feedback

Collect feedback through:
- Play Store reviews
- In-app feedback form
- GitHub issues (if open source)
- Email support

## Additional Resources

- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [ProGuard Documentation](https://www.guardsquare.com/manual/home)
- [Google Play Console](https://play.google.com/console)

## Changelog

### Version 1.0.0+1 (Initial Release)

**Features**:
- Local music library with MediaStore scanning
- Online streaming support
- Professional 10-band equalizer with bass boost
- Background playback with notification controls
- Playlist management
- Smart playlists (Favorites, Recently Played, Most Played)
- Dark and light themes
- French localization
- Sleep timer
- Favorites and play statistics

**Technical**:
- Min SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Flutter: Latest stable
- Code shrinking and obfuscation enabled
- ProGuard rules for audio libraries and database models

---

**Last Updated**: 2024
**Maintained By**: BassPro Player Development Team
