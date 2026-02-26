# Release Build Checklist

Quick reference for building and releasing BassPro Player.

## Pre-Release Checklist

### Code Quality
- [ ] All tests pass: `flutter test`
- [ ] No compiler warnings or errors
- [ ] Code is properly formatted: `flutter format .`
- [ ] Linting passes: `flutter analyze`

### Version Management
- [ ] Version number updated in `pubspec.yaml`
- [ ] Build number incremented
- [ ] CHANGELOG.md updated with release notes

### Testing
- [ ] Tested on Android 5.0 (API 21)
- [ ] Tested on Android 10+ (scoped storage)
- [ ] Tested on Android 14 (target SDK)
- [ ] Tested on different screen sizes
- [ ] All features work correctly:
  - [ ] Library scanning
  - [ ] Local playback
  - [ ] Streaming playback
  - [ ] Background playback
  - [ ] Notification controls
  - [ ] Equalizer
  - [ ] Playlists
  - [ ] Settings
  - [ ] Theme switching
  - [ ] Sleep timer

### Configuration
- [ ] Release build configuration verified
- [ ] ProGuard rules tested
- [ ] Keystore generated (first release only)
- [ ] `key.properties` configured (first release only)
- [ ] Signing configuration updated in `build.gradle.kts` (first release only)

## Build Process

### 1. Clean Build
```bash
flutter clean
flutter pub get
```

### 2. Run Tests
```bash
flutter test
```

### 3. Build Release Artifacts

**For Play Store (recommended):**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**For Direct Distribution:**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**For Optimized APKs (smaller size):**
```bash
flutter build apk --release --split-per-abi
```
Output: Multiple APKs in `build/app/outputs/flutter-apk/`

### 4. Test Release Build
```bash
flutter install --release
```

Or manually:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Post-Build Verification

### Installation Test
- [ ] App installs successfully
- [ ] App launches without crashes
- [ ] No ANR (Application Not Responding) errors

### Functionality Test
- [ ] All core features work
- [ ] No crashes during normal use
- [ ] Performance is smooth (60fps)
- [ ] Memory usage is reasonable
- [ ] Battery usage is acceptable

### ProGuard Verification
- [ ] APK size is reduced (compared to debug)
- [ ] Code is obfuscated (check with APK Analyzer)
- [ ] Resources are shrunk
- [ ] No ClassNotFoundException errors
- [ ] Stack traces are readable (line numbers preserved)

## Distribution

### Google Play Store
1. [ ] Log in to Play Console
2. [ ] Create new release
3. [ ] Upload App Bundle (`.aab`)
4. [ ] Add release notes
5. [ ] Submit for review

### Direct Distribution
1. [ ] Upload APK to hosting
2. [ ] Create download page
3. [ ] Provide installation instructions
4. [ ] Test download and installation

## Post-Release

### Monitoring
- [ ] Monitor crash reports
- [ ] Check user reviews
- [ ] Monitor analytics
- [ ] Track performance metrics

### Documentation
- [ ] Update README.md
- [ ] Update user documentation
- [ ] Announce release (if applicable)

### Backup
- [ ] Backup keystore file
- [ ] Backup key.properties
- [ ] Tag release in git: `git tag v1.0.0`
- [ ] Push tag: `git push origin v1.0.0`

## Quick Commands Reference

```bash
# Clean and prepare
flutter clean && flutter pub get

# Run tests
flutter test

# Build App Bundle (Play Store)
flutter build appbundle --release

# Build APK (Direct distribution)
flutter build apk --release

# Build split APKs (Optimized)
flutter build apk --release --split-per-abi

# Install release build
flutter install --release

# Check APK size
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Analyze APK (requires Android Studio)
# Build → Analyze APK → Select app-release.apk
```

## Troubleshooting

### Build Fails
1. Run `flutter clean`
2. Run `flutter pub get`
3. Check for dependency conflicts
4. Verify Gradle configuration

### App Crashes on Release
1. Check logcat for errors
2. Verify ProGuard rules
3. Test with `--no-shrink` flag
4. Add keep rules for missing classes

### Large APK Size
1. Verify resource shrinking is enabled
2. Remove unused assets
3. Use split APKs per ABI
4. Analyze APK contents

### Signing Issues
1. Verify keystore path in `key.properties`
2. Check passwords are correct
3. Ensure keystore file exists
4. Verify signing config in `build.gradle.kts`

## Important Files

- `pubspec.yaml` - Version number
- `android/app/build.gradle.kts` - Build configuration
- `android/app/proguard-rules.pro` - ProGuard rules
- `android/key.properties` - Keystore configuration (not in git)
- `RELEASE_BUILD.md` - Detailed release guide
- `CHANGELOG.md` - Release notes

## Security Reminders

⚠️ **NEVER commit these files:**
- `*.jks` (keystore files)
- `*.keystore` (keystore files)
- `key.properties` (keystore passwords)

✅ **Always:**
- Keep keystore backup in secure location
- Use strong passwords
- Limit keystore access
- Test release builds thoroughly

## Support

For detailed instructions, see:
- `RELEASE_BUILD.md` - Complete release guide
- `README.md` - Project documentation
- [Flutter Deployment Docs](https://docs.flutter.dev/deployment/android)

---

**Current Version**: 1.0.0+1
**Last Updated**: 2024
