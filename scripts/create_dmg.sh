#!/bin/bash

# Configuration
APP_NAME="Gladden"
DMG_NAME="Gladden-Installer.dmg"
BUILD_PATH="../build/macos/Build/Products/Release"
APP_PATH="$BUILD_PATH/$APP_NAME.app"

# 1. Clean and Build
echo "Building Release version..."
flutter clean
flutter pub get
flutter build macos --release

# Check if build succeeded
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App build failed. $APP_PATH not found."
    exit 1
fi

# 2. Cleanup previous build artifacts
rm -f "$DMG_NAME"

# 3. Create DMG using create-dmg tool
echo "Creating DMG with create-dmg..."

# Verify create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg could not be found. Please install it with: brew install create-dmg"
    exit 1
fi

create-dmg \
  --volname "Gladden Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 200 190 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 600 185 \
  "$DMG_NAME" \
  "$APP_PATH"

echo "Done! $DMG_NAME created successfully."
