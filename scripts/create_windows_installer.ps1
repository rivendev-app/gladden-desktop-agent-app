# Windows Installer Creation Script

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Resolve-Path "$scriptDir\.."
$buildDir = "$rootDir\build\windows\x64\runner\Release"
$issFile = "$rootDir\windows\runner\setup.iss"

Write-Host "=== Gladden Windows Installer Creator ===" -ForegroundColor Cyan

# 1. Build the Flutter Application
Write-Host "Building Release version..." -ForegroundColor Yellow
Set-Location $rootDir
flutter clean
flutter pub get

# Generate ObjectBox code
Write-Host "Generating ObjectBox code..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

flutter build windows --release

if (-not (Test-Path "$buildDir\gladden.exe")) {
    Write-Error "Error: App build failed. $buildDir\gladden.exe not found."
}

# 2. Check for Inno Setup Compiler (ISCC)
$isccPath = Get-Command "ISCC" -ErrorAction SilentlyContinue
if (-not $isccPath) {
    # Check common installation path
    $commonPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    if (Test-Path $commonPath) {
        $isccPath = $commonPath
    }
    else {
        Write-Error "Error: Inno Setup Compiler (ISCC) not found in PATH or standard location. Please install Inno Setup 6+."
    }
}

Write-Host "Found ISCC at: $isccPath" -ForegroundColor Green

# 3. Create Installer using Inno Setup
Write-Host "Creating Installer..." -ForegroundColor Yellow
& $isccPath "$issFile"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Done! Installer created successfully in build/windows/installer." -ForegroundColor Green
}
else {
    Write-Error "Error: Inno Setup compilation failed."
}
