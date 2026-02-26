# BassPro Player - Build Scripts Documentation

This document describes the automated build scripts available for building release artifacts.

## Overview

The project includes automated build scripts to simplify the release build process:

- **build_release.sh** - Bash script for Linux/macOS
- **build_release.ps1** - PowerShell script for Windows
- **pre_build_check.sh** - Pre-build verification script

## Prerequisites

Before using the build scripts, ensure:

1. **Flutter SDK** is installed and in PATH
2. **Android SDK** is configured
3. **Keystore** is generated (for production builds)
4. **key.properties** is configured (for production builds)

See `RELEASE_BUILD.md` for detailed setup instructions.

## Build Scripts

### build_release.sh (Linux/macOS)

Automated release build script for Unix-like systems.

#### Usage

```bash
# Make script executable (first time only)
chmod +x scripts/build_release.sh

# Build all types (APK, App Bundle, Split APKs)
./scripts/build_release.sh

# Build specific type
./scripts/build_release.sh --type apk
./scripts/build_release.sh --type appbundle
./scripts/build_release.sh --type split-apk

# Skip tests (faster build)
./scripts/build_release.sh --skip-tests

# Skip clean step (faster build)
./scripts/build_release.sh --skip-clean

# Quick build (skip tests and clean)
./scripts/build_release.sh --skip-tests --skip-clean

# Show help
./scripts/build_release.sh --help
```

#### Options

- `--type TYPE` - Build type: `apk`, `appbundle`, `split-apk`, or `all` (default: `all`)
- `--skip-tests` - Skip running tests before build
- `--skip-clean` - Skip `flutter clean` step
- `--help` - Show help message

#### What It Does

1. **Cleans** previous builds (optional)
2. **Gets** dependencies with `flutter pub get`
3. **Runs** tests with `flutter test` (optional)
4. **Checks** keystore configuration
5. **Builds** release artifacts based on type
6. **Reports** build results and file sizes

### build_release.ps1 (Windows)

Automated release build script for Windows PowerShell.

#### Usage

```powershell
# Build all types (APK, App Bundle, Split APKs)
.\scripts\build_release.ps1

# Build specific type
.\scripts\build_release.ps1 -BuildType apk
.\scripts\build_release.ps1 -BuildType appbundle
.\scripts\build_release.ps1 -BuildType split-apk

# Skip tests (faster build)
.\scripts\build_release.ps1 -SkipTests

# Skip clean step (faster build)
.\scripts\build_release.ps1 -SkipClean

# Quick build (skip tests and clean)
.\scripts\build_release.ps1 -SkipTests -SkipClean

# Combine options
.\scripts\build_release.ps1 -BuildType apk -SkipTests
```

#### Parameters

- `-BuildType` - Build type: `apk`, `appbundle`, `split-apk`, or `all` (default: `all`)
- `-SkipTests` - Skip running tests before build
- `-SkipClean` - Skip `flutter clean` step

#### What It Does

Same as the bash script:

1. Cleans previous builds (optional)
2. Gets dependencies
3. Runs tests (optional)
4. Checks keystore configuration
5. Builds release artifacts
6. Reports results

### pre_build_check.sh (Linux/macOS)

Pre-build verification script that checks if the project is ready for release.

#### Usage

```bash
# Make script executable (first time only)
chmod +x scripts/pre_build_check.sh

# Run checks
./scripts/pre_build_check.sh
```

#### What It Checks

1. **Flutter Installation** - Verifies Flutter is installed and accessible
2. **Project Structure** - Checks for required files and directories
3. **Version Number** - Verifies version is set in pubspec.yaml
4. **Android Configuration** - Checks build.gradle.kts settings
5. **ProGuard Rules** - Verifies ProGuard configuration exists
6. **Keystore Configuration** - Checks for key.properties (warns if missing)
7. **Dependencies** - Verifies critical dependencies are present
8. **Assets** - Checks for required asset directories
9. **Documentation** - Verifies documentation files exist
10. **Git Status** - Checks for uncommitted changes and version tags

#### Exit Codes

- `0` - All checks passed, ready to build
- `1` - Critical issues found, fix before building

## Build Output Locations

After a successful build, artifacts are located at:

### APK (Direct Distribution)
```
build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (Google Play Store)
```
build/app/outputs/bundle/release/app-release.aab
```

### Split APKs (Optimized Distribution)
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

## Typical Workflow

### First-Time Setup

1. **Generate keystore** (one-time):
   ```bash
   keytool -genkey -v -keystore ~/basspro-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias basspro
   ```

2. **Create key.properties**:
   ```bash
   cat > android/key.properties << EOF
   storePassword=YOUR_PASSWORD
   keyPassword=YOUR_PASSWORD
   keyAlias=basspro
   storeFile=/path/to/basspro-release-key.jks
   EOF
   ```

3. **Configure signing** in `android/app/build.gradle.kts` (see RELEASE_BUILD.md)

### Regular Release Build

1. **Update version** in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2
   ```

2. **Update CHANGELOG.md** with release notes

3. **Run pre-build check**:
   ```bash
   ./scripts/pre_build_check.sh
   ```

4. **Build release**:
   ```bash
   ./scripts/build_release.sh
   ```

5. **Test release build**:
   ```bash
   flutter install --release
   # Or manually: adb install build/app/outputs/flutter-apk/app-release.apk
   ```

6. **Verify functionality** (see RELEASE_CHECKLIST.md)

7. **Tag release**:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

8. **Distribute**:
   - Upload App Bundle to Google Play Store, or
   - Distribute APK directly

### Quick Development Build

For testing release configuration without full checks:

```bash
# Linux/macOS
./scripts/build_release.sh --type apk --skip-tests --skip-clean

# Windows
.\scripts\build_release.ps1 -BuildType apk -SkipTests -SkipClean
```

## Build Types Explained

### APK (app-release.apk)

- **Use for**: Direct distribution, testing
- **Size**: ~15-25 MB (with ProGuard)
- **Pros**: Single file, easy to distribute
- **Cons**: Larger than split APKs, includes all ABIs

### App Bundle (app-release.aab)

- **Use for**: Google Play Store (recommended)
- **Size**: ~20-30 MB
- **Pros**: Play Store optimizes downloads per device
- **Cons**: Can only be uploaded to Play Store

### Split APKs (per ABI)

- **Use for**: Optimized direct distribution
- **Size**: ~8-12 MB each
- **Pros**: Smaller downloads, optimized per architecture
- **Cons**: Multiple files, need to distribute correct one

**Split APK Architectures**:
- `armeabi-v7a` - 32-bit ARM (older devices)
- `arm64-v8a` - 64-bit ARM (most modern devices)
- `x86_64` - 64-bit x86 (emulators, some tablets)

## Troubleshooting

### Script Permission Denied

**Linux/macOS**:
```bash
chmod +x scripts/build_release.sh
chmod +x scripts/pre_build_check.sh
```

### PowerShell Execution Policy

**Windows**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Build Fails with Keystore Error

1. Verify `android/key.properties` exists
2. Check keystore file path is correct
3. Verify passwords are correct
4. Ensure signing config is in `build.gradle.kts`

### Tests Fail

1. Fix failing tests before building release
2. Or use `--skip-tests` flag (not recommended for production)

### Large APK Size

1. Verify ProGuard is enabled in `build.gradle.kts`
2. Check `proguard-rules.pro` exists
3. Use split APKs for smaller downloads
4. Remove unused assets

### Build Succeeds but App Crashes

1. Check logcat for errors
2. Verify ProGuard rules are correct
3. Test with `--no-shrink` flag to isolate issue
4. Add keep rules for missing classes

## Manual Build Commands

If you prefer manual builds without scripts:

```bash
# Clean
flutter clean

# Get dependencies
flutter pub get

# Run tests
flutter test

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Build split APKs
flutter build apk --release --split-per-abi

# Install release build
flutter install --release
```

## Continuous Integration

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
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build App Bundle
        run: flutter build appbundle --release
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: release-bundle
          path: build/app/outputs/bundle/release/app-release.aab
```

### Using Build Scripts in CI

```yaml
- name: Run pre-build check
  run: |
    chmod +x scripts/pre_build_check.sh
    ./scripts/pre_build_check.sh

- name: Build release
  run: |
    chmod +x scripts/build_release.sh
    ./scripts/build_release.sh --type appbundle
```

## Best Practices

1. **Always run tests** before building release (don't skip unless necessary)
2. **Use pre-build check** to catch issues early
3. **Test release builds** on physical devices before distribution
4. **Keep keystore secure** - never commit to version control
5. **Tag releases** in Git for version tracking
6. **Update CHANGELOG.md** with each release
7. **Increment build number** for every release
8. **Use App Bundle** for Play Store distribution
9. **Use split APKs** for optimized direct distribution
10. **Backup keystore** in secure location

## Security Checklist

Before running build scripts:

- [ ] Keystore file is NOT in version control
- [ ] key.properties is NOT in version control
- [ ] .gitignore includes `*.jks`, `*.keystore`, `key.properties`
- [ ] Keystore backup exists in secure location
- [ ] Passwords are strong and stored securely
- [ ] Only authorized team members have keystore access

## Additional Resources

- **RELEASE_BUILD.md** - Comprehensive release guide
- **RELEASE_CHECKLIST.md** - Release testing checklist
- **README.md** - Project documentation
- **CHANGELOG.md** - Version history
- [Flutter Deployment](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

## Support

For issues with build scripts:

1. Check this documentation
2. Review RELEASE_BUILD.md
3. Verify prerequisites are met
4. Check Flutter and Android SDK versions
5. Review error messages carefully

## Script Maintenance

The build scripts are maintained in the `scripts/` directory:

- `build_release.sh` - Bash build script
- `build_release.ps1` - PowerShell build script
- `pre_build_check.sh` - Pre-build verification

To update scripts:
1. Edit the script file
2. Test thoroughly
3. Update this documentation
4. Commit changes

---

**Last Updated**: 2024
**Version**: 1.0.0
**Maintained By**: BassPro Player Development Team

