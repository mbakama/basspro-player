# BassPro Player - Release Build Script (PowerShell)
# This script automates the release build process

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('apk', 'appbundle', 'split-apk', 'all')]
    [string]$BuildType = 'all',
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipClean
)

# Color output functions
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }

# Header
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  BassPro Player - Release Build" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

# Check if we're in the correct directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
}

# Get version from pubspec.yaml
$version = (Select-String -Path "pubspec.yaml" -Pattern "^version:\s*(.+)$").Matches.Groups[1].Value
Write-Info "Building version: $version"

# Step 1: Clean (optional)
if (-not $SkipClean) {
    Write-Info "`n[1/6] Cleaning previous builds..."
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter clean failed!"
        exit 1
    }
    Write-Success "✓ Clean complete"
} else {
    Write-Warning "`n[1/6] Skipping clean step"
}

# Step 2: Get dependencies
Write-Info "`n[2/6] Getting dependencies..."
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter pub get failed!"
    exit 1
}
Write-Success "✓ Dependencies retrieved"

# Step 3: Run tests (optional)
if (-not $SkipTests) {
    Write-Info "`n[3/6] Running tests..."
    flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Tests failed! Fix tests before building release."
        exit 1
    }
    Write-Success "✓ All tests passed"
} else {
    Write-Warning "`n[3/6] Skipping tests"
}

# Step 4: Check for keystore configuration
Write-Info "`n[4/6] Checking keystore configuration..."
if (-not (Test-Path "android/key.properties")) {
    Write-Warning "⚠ Warning: android/key.properties not found!"
    Write-Warning "The build will use debug signing. For production release:"
    Write-Warning "1. Generate a keystore (see RELEASE_BUILD.md)"
    Write-Warning "2. Create android/key.properties"
    Write-Warning "3. Configure signing in android/app/build.gradle.kts"
    Write-Host ""
    $continue = Read-Host "Continue with debug signing? (y/N)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Info "Build cancelled. Please configure keystore first."
        exit 0
    }
} else {
    Write-Success "✓ Keystore configuration found"
}

# Step 5: Build release artifacts
Write-Info "`n[5/6] Building release artifacts..."

$buildSuccess = $true

if ($BuildType -eq 'apk' -or $BuildType -eq 'all') {
    Write-Info "`nBuilding release APK..."
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "✗ APK build failed!"
        $buildSuccess = $false
    } else {
        Write-Success "✓ APK build complete"
        $apkPath = "build/app/outputs/flutter-apk/app-release.apk"
        if (Test-Path $apkPath) {
            $apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
            Write-Info "  Location: $apkPath"
            Write-Info "  Size: $apkSize MB"
        }
    }
}

if ($BuildType -eq 'appbundle' -or $BuildType -eq 'all') {
    Write-Info "`nBuilding release App Bundle..."
    flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "✗ App Bundle build failed!"
        $buildSuccess = $false
    } else {
        Write-Success "✓ App Bundle build complete"
        $aabPath = "build/app/outputs/bundle/release/app-release.aab"
        if (Test-Path $aabPath) {
            $aabSize = [math]::Round((Get-Item $aabPath).Length / 1MB, 2)
            Write-Info "  Location: $aabPath"
            Write-Info "  Size: $aabSize MB"
        }
    }
}

if ($BuildType -eq 'split-apk' -or $BuildType -eq 'all') {
    Write-Info "`nBuilding split APKs..."
    flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) {
        Write-Error "✗ Split APK build failed!"
        $buildSuccess = $false
    } else {
        Write-Success "✓ Split APK build complete"
        $splitApkDir = "build/app/outputs/flutter-apk"
        if (Test-Path $splitApkDir) {
            Write-Info "  Split APKs:"
            Get-ChildItem "$splitApkDir/app-*-release.apk" | ForEach-Object {
                $size = [math]::Round($_.Length / 1MB, 2)
                Write-Info "    - $($_.Name) ($size MB)"
            }
        }
    }
}

if (-not $buildSuccess) {
    Write-Error "`nBuild failed! Check errors above."
    exit 1
}

# Step 6: Summary
Write-Info "`n[6/6] Build Summary"
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Success "✓ Release build complete!"
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Info "Version: $version"
Write-Info "Build type: $BuildType"

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Test the release build on physical devices"
Write-Host "2. Verify all features work correctly"
Write-Host "3. Check performance and memory usage"
Write-Host "4. Review RELEASE_CHECKLIST.md for full testing"
Write-Host ""

if ($BuildType -eq 'appbundle' -or $BuildType -eq 'all') {
    Write-Info "For Google Play Store:"
    Write-Info "  Upload: build/app/outputs/bundle/release/app-release.aab"
}

if ($BuildType -eq 'apk' -or $BuildType -eq 'all') {
    Write-Info "`nFor direct distribution:"
    Write-Info "  Use: build/app/outputs/flutter-apk/app-release.apk"
}

if ($BuildType -eq 'split-apk' -or $BuildType -eq 'all') {
    Write-Info "`nFor optimized distribution:"
    Write-Info "  Use split APKs in: build/app/outputs/flutter-apk/"
}

Write-Host ""
