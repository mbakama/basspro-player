#!/bin/bash
# BassPro Player - Release Build Script (Bash)
# This script automates the release build process

set -e  # Exit on error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default values
BUILD_TYPE="all"
SKIP_TESTS=false
SKIP_CLEAN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-clean)
            SKIP_CLEAN=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --type TYPE        Build type: apk, appbundle, split-apk, all (default: all)"
            echo "  --skip-tests       Skip running tests"
            echo "  --skip-clean       Skip flutter clean step"
            echo "  --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Build all types"
            echo "  $0 --type apk                # Build APK only"
            echo "  $0 --type appbundle          # Build App Bundle only"
            echo "  $0 --skip-tests --skip-clean # Quick build without tests/clean"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate build type
if [[ ! "$BUILD_TYPE" =~ ^(apk|appbundle|split-apk|all)$ ]]; then
    echo -e "${RED}Invalid build type: $BUILD_TYPE${NC}"
    echo "Valid types: apk, appbundle, split-apk, all"
    exit 1
fi

# Header
echo -e "\n${MAGENTA}========================================"
echo -e "  BassPro Player - Release Build"
echo -e "========================================${NC}\n"

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
echo -e "${CYAN}Building version: $VERSION${NC}"

# Step 1: Clean (optional)
if [ "$SKIP_CLEAN" = false ]; then
    echo -e "\n${CYAN}[1/6] Cleaning previous builds...${NC}"
    flutter clean
    echo -e "${GREEN}✓ Clean complete${NC}"
else
    echo -e "\n${YELLOW}[1/6] Skipping clean step${NC}"
fi

# Step 2: Get dependencies
echo -e "\n${CYAN}[2/6] Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies retrieved${NC}"

# Step 3: Run tests (optional)
if [ "$SKIP_TESTS" = false ]; then
    echo -e "\n${CYAN}[3/6] Running tests...${NC}"
    if flutter test; then
        echo -e "${GREEN}✓ All tests passed${NC}"
    else
        echo -e "${RED}Tests failed! Fix tests before building release.${NC}"
        exit 1
    fi
else
    echo -e "\n${YELLOW}[3/6] Skipping tests${NC}"
fi

# Step 4: Check for keystore configuration
echo -e "\n${CYAN}[4/6] Checking keystore configuration...${NC}"
if [ ! -f "android/key.properties" ]; then
    echo -e "${YELLOW}⚠ Warning: android/key.properties not found!${NC}"
    echo -e "${YELLOW}The build will use debug signing. For production release:${NC}"
    echo -e "${YELLOW}1. Generate a keystore (see RELEASE_BUILD.md)${NC}"
    echo -e "${YELLOW}2. Create android/key.properties${NC}"
    echo -e "${YELLOW}3. Configure signing in android/app/build.gradle.kts${NC}"
    echo ""
    read -p "Continue with debug signing? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Build cancelled. Please configure keystore first.${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}✓ Keystore configuration found${NC}"
fi

# Step 5: Build release artifacts
echo -e "\n${CYAN}[5/6] Building release artifacts...${NC}"

BUILD_SUCCESS=true

if [[ "$BUILD_TYPE" == "apk" || "$BUILD_TYPE" == "all" ]]; then
    echo -e "\n${CYAN}Building release APK...${NC}"
    if flutter build apk --release; then
        echo -e "${GREEN}✓ APK build complete${NC}"
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
        if [ -f "$APK_PATH" ]; then
            APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
            echo -e "${CYAN}  Location: $APK_PATH${NC}"
            echo -e "${CYAN}  Size: $APK_SIZE${NC}"
        fi
    else
        echo -e "${RED}✗ APK build failed!${NC}"
        BUILD_SUCCESS=false
    fi
fi

if [[ "$BUILD_TYPE" == "appbundle" || "$BUILD_TYPE" == "all" ]]; then
    echo -e "\n${CYAN}Building release App Bundle...${NC}"
    if flutter build appbundle --release; then
        echo -e "${GREEN}✓ App Bundle build complete${NC}"
        AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
        if [ -f "$AAB_PATH" ]; then
            AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
            echo -e "${CYAN}  Location: $AAB_PATH${NC}"
            echo -e "${CYAN}  Size: $AAB_SIZE${NC}"
        fi
    else
        echo -e "${RED}✗ App Bundle build failed!${NC}"
        BUILD_SUCCESS=false
    fi
fi

if [[ "$BUILD_TYPE" == "split-apk" || "$BUILD_TYPE" == "all" ]]; then
    echo -e "\n${CYAN}Building split APKs...${NC}"
    if flutter build apk --release --split-per-abi; then
        echo -e "${GREEN}✓ Split APK build complete${NC}"
        SPLIT_APK_DIR="build/app/outputs/flutter-apk"
        if [ -d "$SPLIT_APK_DIR" ]; then
            echo -e "${CYAN}  Split APKs:${NC}"
            for apk in "$SPLIT_APK_DIR"/app-*-release.apk; do
                if [ -f "$apk" ]; then
                    SIZE=$(du -h "$apk" | cut -f1)
                    NAME=$(basename "$apk")
                    echo -e "${CYAN}    - $NAME ($SIZE)${NC}"
                fi
            done
        fi
    else
        echo -e "${RED}✗ Split APK build failed!${NC}"
        BUILD_SUCCESS=false
    fi
fi

if [ "$BUILD_SUCCESS" = false ]; then
    echo -e "\n${RED}Build failed! Check errors above.${NC}"
    exit 1
fi

# Step 6: Summary
echo -e "\n${CYAN}[6/6] Build Summary${NC}"
echo -e "\n${MAGENTA}========================================"
echo -e "${GREEN}✓ Release build complete!${NC}"
echo -e "${MAGENTA}========================================${NC}\n"

echo -e "${CYAN}Version: $VERSION${NC}"
echo -e "${CYAN}Build type: $BUILD_TYPE${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Test the release build on physical devices"
echo "2. Verify all features work correctly"
echo "3. Check performance and memory usage"
echo "4. Review RELEASE_CHECKLIST.md for full testing"
echo ""

if [[ "$BUILD_TYPE" == "appbundle" || "$BUILD_TYPE" == "all" ]]; then
    echo -e "${CYAN}For Google Play Store:${NC}"
    echo -e "${CYAN}  Upload: build/app/outputs/bundle/release/app-release.aab${NC}"
fi

if [[ "$BUILD_TYPE" == "apk" || "$BUILD_TYPE" == "all" ]]; then
    echo -e "\n${CYAN}For direct distribution:${NC}"
    echo -e "${CYAN}  Use: build/app/outputs/flutter-apk/app-release.apk${NC}"
fi

if [[ "$BUILD_TYPE" == "split-apk" || "$BUILD_TYPE" == "all" ]]; then
    echo -e "\n${CYAN}For optimized distribution:${NC}"
    echo -e "${CYAN}  Use split APKs in: build/app/outputs/flutter-apk/${NC}"
fi

echo ""
