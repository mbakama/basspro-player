# BassPro Player - Build Quick Reference

Quick reference card for building release artifacts.

## Prerequisites

- Flutter SDK installed
- Android SDK configured
- Keystore generated (for production)
- key.properties configured (for production)

## Quick Commands

### Windows (PowerShell)

```powershell
# Build everything
.\scripts\build_release.ps1

# Build APK only
.\scripts\build_release.ps1 -BuildType apk

# Build App Bundle only
.\scripts\build_release.ps1 -BuildType appbundle

# Quick build (skip tests)
.\scripts\build_release.ps1 -SkipTests

# Fast build (skip tests and clean)
.\scripts\build_release.ps1 -SkipTests -SkipClean
```

### Linux/macOS (Bash)

```bash
# Make scripts executable (first time only)
chmod +x scripts/*.sh

# Build everything
./scripts/build_release.sh

# Build APK only
./scripts/build_release.sh --type apk

# Build App Bundle only
./scripts/build_release.sh --type appbundle

# Quick build (skip tests)
./scripts/build_release.sh --skip-tests

# Fast build (skip tests and clean)
./scripts/build_release.sh --skip-tests --skip-clean

# Pre-build check
./scripts/pre_build_check.sh
```

## Manual Commands

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

# Install release
flutter install --release
```

## Output Locations

```
build/app/outputs/
├── flutter-apk/
│   ├── app-release.apk              # Universal APK
│   ├── app-armeabi-v7a-release.apk  # 32-bit ARM
│   ├── app-arm64-v8a-release.apk    # 64-bit ARM
│   └── app-x86_64-release.apk       # x86_64
└── bundle/release/
    └── app-release.aab              # App Bundle
```

## Build Types

| Type | Command | Use For | Size |
|------|---------|---------|------|
| APK | `--type apk` | Direct distribution | ~15-25 MB |
| Bundle | `--type appbundle` | Play Store | ~20-30 MB |
| Split | `--type split-apk` | Optimized distribution | ~8-12 MB each |

## Installation

```bash
# Using Flutter
flutter install --release

# Using ADB
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied | `chmod +x scripts/*.sh` |
| Keystore not found | Create `android/key.properties` |
| Tests fail | Fix tests or use `--skip-tests` |
| Large APK | Verify ProGuard is enabled |

## Version Update

```yaml
# pubspec.yaml
version: 1.0.1+2
#        ^     ^
#        |     +-- Build number (increment)
#        +-------- Version name (semantic)
```

## Release Workflow

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Run `./scripts/pre_build_check.sh` (Linux/macOS)
4. Run `./scripts/build_release.sh` or `.ps1`
5. Test release build
6. Tag release: `git tag v1.0.1`
7. Distribute

## Documentation

- **BUILD_SCRIPTS.md** - Complete build scripts guide
- **RELEASE_BUILD.md** - Detailed release guide
- **RELEASE_CHECKLIST.md** - Testing checklist
- **TASK_36.4_BUILD_ARTIFACTS.md** - Implementation summary

## Support

For detailed instructions, see the documentation files above.

---

**Version**: 1.0.0+1
**Last Updated**: 2024

