#!/bin/bash

# Configuration
APP_NAME="gladden"
DISPLAY_NAME="Gladden"
VERSION="1.0.0"
MAINTAINER="Pedrov <pedro@example.com>"
DESCRIPTION="Gladden Desktop Agent"
SECTION="utils"
PRIORITY="optional"
ARCHITECTURE="amd64"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
DEB_ROOT="$ROOT_DIR/build/linux/deb"
DEB_FILE="$SCRIPT_DIR/gladden-installer.deb"

# 1. Build the Flutter Application
echo "Building Release version..."
cd "$ROOT_DIR"
flutter clean
flutter pub get
flutter build linux --release

# Check if build succeeded
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: App build failed. $BUILD_DIR not found."
    exit 1
fi

# 2. Prepare DEB structure
echo "Preparing DEB structure..."
rm -rf "$DEB_ROOT"
mkdir -p "$DEB_ROOT/usr/bin"
mkdir -p "$DEB_ROOT/usr/lib/$APP_NAME"
mkdir -p "$DEB_ROOT/usr/share/applications"
mkdir -p "$DEB_ROOT/usr/share/pixmaps"
mkdir -p "$DEB_ROOT/DEBIAN"

# Copy build files
cp -r "$BUILD_DIR/." "$DEB_ROOT/usr/lib/$APP_NAME/"

# Create executable symlink
ln -s "/usr/lib/$APP_NAME/$APP_NAME" "$DEB_ROOT/usr/bin/$APP_NAME"

# Copy icon
if [ -f "$ROOT_DIR/assets/images/app_icon.png" ]; then
    cp "$ROOT_DIR/assets/images/app_icon.png" "$DEB_ROOT/usr/share/pixmaps/$APP_NAME.png"
fi

# 3. Create .desktop file
echo "Creating .desktop file..."
cat > "$DEB_ROOT/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Version=1.0
Name=$DISPLAY_NAME
Comment=$DESCRIPTION
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Utility;
EOF

# 4. Create control file
echo "Creating control file..."
cat > "$DEB_ROOT/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Section: $SECTION
Priority: $PRIORITY
Architecture: $ARCHITECTURE
Maintainer: $MAINTAINER
Description: $DESCRIPTION
Depends: libgtk-3-0, libsecret-1-0, libjsoncpp25
EOF

# 5. Build the DEB package
echo "Building DEB package..."
dpkg-deb --build "$DEB_ROOT" "$DEB_FILE"

echo "Done! $DEB_FILE created successfully."
