#!/bin/bash

# Configuration
APP_NAME="gladden"
DISPLAY_NAME="Gladden"
GITHUB_USER="rivendev-app"
GITHUB_REPO="gladden-desktop-agent-app"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check for remote flag
REMOTE_MODE=false
if [[ "$1" == "--remote" ]]; then
    REMOTE_MODE=true
    ROOT_DIR="/tmp/gladden-install"
    rm -rf "$ROOT_DIR"
    mkdir -p "$ROOT_DIR"
fi

BUILD_DIR="$ROOT_DIR/build/linux/x64/release/bundle"

# Destination directories (local user level)
BIN_DEST="$HOME/.local/bin"
LIB_DEST="$HOME/.local/lib/$APP_NAME"
APPS_DEST="$HOME/.local/share/applications"
ICON_DEST="$HOME/.local/share/pixmaps"

echo "=== Gladden Terminal Installer ==="

# 1. Handle Remote Download or Local Build
if [ "$REMOTE_MODE" = true ]; then
    echo "Remote mode enabled. Downloading latest release..."
    # Replace with your actual asset URL or use GitHub API to find it
    RELEASE_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/latest/download/gladden-linux.tar.gz"
    
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is required for remote installation."
        exit 1
    fi
    
    mkdir -p "$BUILD_DIR"
    echo "Downloading from $RELEASE_URL..."
    # Note: This is a placeholder. You'll need to upload a .tar.gz of your 'bundle' folder to GitHub.
    curl -L "$RELEASE_URL" | tar -xz -C "$BUILD_DIR"
    
    if [ ! -d "$BUILD_DIR" ]; then
        echo "Error: Failed to download or extract the release. Ensure the URL is correct and the file is a .tar.gz of the 'bundle' directory."
        exit 1
    fi
elif [ ! -d "$BUILD_DIR" ]; then
    echo "Release build not found. Building now..."
    cd "$ROOT_DIR"
    flutter pub get
    flutter build linux --release
    if [ ! -d "$BUILD_DIR" ]; then
        echo "Error: Build failed. Aborting."
        exit 1
    fi
fi

# 2. Create destination directories
echo "Creating local directories..."
mkdir -p "$BIN_DEST"
mkdir -p "$LIB_DEST"
mkdir -p "$APPS_DEST"
mkdir -p "$ICON_DEST"

# 3. Copy files
echo "Installing files to $LIB_DEST..."
cp -r "$BUILD_DIR/." "$LIB_DEST/"

# 4. Create symlink in bin
echo "Creating symlink in $BIN_DEST..."
ln -sf "$LIB_DEST/$APP_NAME" "$BIN_DEST/$APP_NAME"

# 5. Copy icon
if [ -f "$ROOT_DIR/assets/images/app_icon.png" ]; then
    cp "$ROOT_DIR/assets/images/app_icon.png" "$ICON_DEST/$APP_NAME.png"
fi

# 6. Create .desktop file
echo "Registering application in menu..."
cat > "$APPS_DEST/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Version=1.0
Name=$DISPLAY_NAME
Comment=Gladden Desktop Agent
Exec=$BIN_DEST/$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Utility;
EOF

echo ""
echo "Installation complete!"
echo "You can now launch the app from your menu or by typing '$APP_NAME' in the terminal."
echo "Note: Ensure $BIN_DEST is in your PATH."
