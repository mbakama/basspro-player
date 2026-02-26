#!/bin/bash
# BassPro Player - Pre-Build Check Script
# Verifies that the project is ready for release build

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

ISSUES_FOUND=0

echo -e "\n${MAGENTA}========================================"
echo -e "  BassPro Player - Pre-Build Check"
echo -e "========================================${NC}\n"

# Check 1: Flutter installation
echo -e "${CYAN}[1/10] Checking Flutter installation...${NC}"
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✓ Flutter found: $FLUTTER_VERSION${NC}"
else
    echo -e "${RED}✗ Flutter not found in PATH${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 2: Project structure
echo -e "\n${CYAN}[2/10] Checking project structure...${NC}"
if [ -f "pubspec.yaml" ]; then
    echo -e "${GREEN}✓ pubspec.yaml found${NC}"
else
    echo -e "${RED}✗ pubspec.yaml not found${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ -d "android" ]; then
    echo -e "${GREEN}✓ android/ directory found${NC}"
else
    echo -e "${RED}✗ android/ directory not found${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 3: Version number
echo -e "\n${CYAN}[3/10] Checking version number...${NC}"
if [ -f "pubspec.yaml" ]; then
    VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
    if [ -n "$VERSION" ]; then
        echo -e "${GREEN}✓ Version: $VERSION${NC}"
    else
        echo -e "${RED}✗ Version not found in pubspec.yaml${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
fi

# Check 4: Android configuration
echo -e "\n${CYAN}[4/10] Checking Android configuration...${NC}"
if [ -f "android/app/build.gradle.kts" ]; then
    echo -e "${GREEN}✓ build.gradle.kts found${NC}"
    
    # Check minSdk
    if grep -q "minSdk = 21" android/app/build.gradle.kts; then
        echo -e "${GREEN}✓ minSdk = 21${NC}"
    else
        echo -e "${YELLOW}⚠ minSdk might not be set to 21${NC}"
    fi
    
    # Check targetSdk
    if grep -q "targetSdk = 34" android/app/build.gradle.kts; then
        echo -e "${GREEN}✓ targetSdk = 34${NC}"
    else
        echo -e "${YELLOW}⚠ targetSdk might not be set to 34${NC}"
    fi
else
    echo -e "${RED}✗ build.gradle.kts not found${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 5: ProGuard rules
echo -e "\n${CYAN}[5/10] Checking ProGuard configuration...${NC}"
if [ -f "android/app/proguard-rules.pro" ]; then
    echo -e "${GREEN}✓ proguard-rules.pro found${NC}"
    
    # Check for critical keep rules
    if grep -q "audio_service" android/app/proguard-rules.pro; then
        echo -e "${GREEN}✓ audio_service keep rules present${NC}"
    else
        echo -e "${YELLOW}⚠ audio_service keep rules might be missing${NC}"
    fi
    
    if grep -q "just_audio" android/app/proguard-rules.pro; then
        echo -e "${GREEN}✓ just_audio keep rules present${NC}"
    else
        echo -e "${YELLOW}⚠ just_audio keep rules might be missing${NC}"
    fi
else
    echo -e "${RED}✗ proguard-rules.pro not found${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 6: Keystore configuration
echo -e "\n${CYAN}[6/10] Checking keystore configuration...${NC}"
if [ -f "android/key.properties" ]; then
    echo -e "${GREEN}✓ key.properties found${NC}"
    
    # Check for required properties
    if grep -q "storePassword" android/key.properties && \
       grep -q "keyPassword" android/key.properties && \
       grep -q "keyAlias" android/key.properties && \
       grep -q "storeFile" android/key.properties; then
        echo -e "${GREEN}✓ All required properties present${NC}"
    else
        echo -e "${YELLOW}⚠ Some properties might be missing${NC}"
    fi
else
    echo -e "${YELLOW}⚠ key.properties not found (will use debug signing)${NC}"
    echo -e "${YELLOW}  For production release, create android/key.properties${NC}"
fi

# Check 7: Dependencies
echo -e "\n${CYAN}[7/10] Checking dependencies...${NC}"
if [ -f "pubspec.lock" ]; then
    echo -e "${GREEN}✓ pubspec.lock found${NC}"
    
    # Check for critical dependencies
    if grep -q "audio_service:" pubspec.lock; then
        echo -e "${GREEN}✓ audio_service dependency present${NC}"
    else
        echo -e "${RED}✗ audio_service dependency missing${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
    
    if grep -q "just_audio:" pubspec.lock; then
        echo -e "${GREEN}✓ just_audio dependency present${NC}"
    else
        echo -e "${RED}✗ just_audio dependency missing${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
else
    echo -e "${YELLOW}⚠ pubspec.lock not found (run 'flutter pub get')${NC}"
fi

# Check 8: Assets
echo -e "\n${CYAN}[8/10] Checking assets...${NC}"
if [ -d "assets" ]; then
    echo -e "${GREEN}✓ assets/ directory found${NC}"
    
    # Check for icon
    if [ -d "assets/icon" ]; then
        echo -e "${GREEN}✓ assets/icon/ directory found${NC}"
    else
        echo -e "${YELLOW}⚠ assets/icon/ directory not found${NC}"
    fi
    
    # Check for images
    if [ -d "assets/images" ]; then
        echo -e "${GREEN}✓ assets/images/ directory found${NC}"
    else
        echo -e "${YELLOW}⚠ assets/images/ directory not found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ assets/ directory not found${NC}"
fi

# Check 9: Documentation
echo -e "\n${CYAN}[9/10] Checking documentation...${NC}"
DOCS_COMPLETE=true

if [ -f "README.md" ]; then
    echo -e "${GREEN}✓ README.md found${NC}"
else
    echo -e "${YELLOW}⚠ README.md not found${NC}"
    DOCS_COMPLETE=false
fi

if [ -f "RELEASE_BUILD.md" ]; then
    echo -e "${GREEN}✓ RELEASE_BUILD.md found${NC}"
else
    echo -e "${YELLOW}⚠ RELEASE_BUILD.md not found${NC}"
    DOCS_COMPLETE=false
fi

if [ -f "RELEASE_CHECKLIST.md" ]; then
    echo -e "${GREEN}✓ RELEASE_CHECKLIST.md found${NC}"
else
    echo -e "${YELLOW}⚠ RELEASE_CHECKLIST.md not found${NC}"
    DOCS_COMPLETE=false
fi

if [ -f "CHANGELOG.md" ]; then
    echo -e "${GREEN}✓ CHANGELOG.md found${NC}"
else
    echo -e "${YELLOW}⚠ CHANGELOG.md not found${NC}"
    DOCS_COMPLETE=false
fi

# Check 10: Git status
echo -e "\n${CYAN}[10/10] Checking Git status...${NC}"
if command -v git &> /dev/null && [ -d ".git" ]; then
    if [ -z "$(git status --porcelain)" ]; then
        echo -e "${GREEN}✓ Working directory clean${NC}"
    else
        echo -e "${YELLOW}⚠ Uncommitted changes present${NC}"
        echo -e "${YELLOW}  Consider committing changes before release build${NC}"
    fi
    
    # Check for version tag
    if git tag | grep -q "^v$VERSION$"; then
        echo -e "${GREEN}✓ Version tag v$VERSION exists${NC}"
    else
        echo -e "${YELLOW}⚠ Version tag v$VERSION not found${NC}"
        echo -e "${YELLOW}  Consider tagging release: git tag v$VERSION${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Not a Git repository${NC}"
fi

# Summary
echo -e "\n${MAGENTA}========================================"
echo -e "  Check Summary"
echo -e "========================================${NC}\n"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo -e "${GREEN}✓ Project is ready for release build${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Run: ./scripts/build_release.sh"
    echo "2. Or: flutter build appbundle --release"
    echo "3. Test the release build thoroughly"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Found $ISSUES_FOUND critical issue(s)${NC}"
    echo -e "${RED}✗ Please fix issues before building release${NC}"
    echo ""
    exit 1
fi
