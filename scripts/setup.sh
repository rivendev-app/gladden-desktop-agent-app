#!/bin/bash

# Configuration
APP_NAME="gladden"
DISPLAY_NAME="Gladden"
VERSION="v1.0.0"
REPO="rivendev-app/gladden-desktop-agent-app"
BASE_URL="https://github.com/$REPO/releases/download/$VERSION"

echo "=== Gladden Remote Installer ==="

# 1. Detection
IS_DEBIAN=false
if [ -f /etc/debian_version ]; then
    IS_DEBIAN=true
fi

# 2. Installation
if [ "$IS_DEBIAN" = true ]; then
    echo "Detected Debian-based system (Ubuntu/Debian/Mint...)"
    DEB_NAME="gladden-installer.deb"
    DEB_URL="$BASE_URL/$DEB_NAME"
    
    echo "Downloading $DEB_NAME..."
    curl -L "$DEB_URL" -o "/tmp/$DEB_NAME"
    
    echo "Installing $DEB_NAME (requires sudo)..."
    sudo apt-get update
    sudo apt-get install -y "/tmp/$DEB_NAME"
    
    rm "/tmp/$DEB_NAME"
else
    echo "Detected non-Debian system. Using AppImage..."
    APPIMAGE_NAME="Gladden.AppImage"
    APPIMAGE_URL="$BASE_URL/$APPIMAGE_NAME"
    
    BIN_DEST="$HOME/.local/bin"
    mkdir -p "$BIN_DEST"
    
    echo "Downloading $APPIMAGE_NAME..."
    curl -L "$APPIMAGE_URL" -o "$BIN_DEST/$APP_NAME"
    chmod +x "$BIN_DEST/$APP_NAME"
    
    echo "Application installed to $BIN_DEST/$APP_NAME"
    echo "Please ensure $BIN_DEST is in your PATH."
fi

echo ""
echo "Installation complete! You can now launch '$APP_NAME' from your terminal or menu."
