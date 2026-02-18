#!/bin/bash

# Configuration
APP_NAME="gladden"
DISPLAY_NAME="Gladden"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
APPDIR="$ROOT_DIR/build/linux/AppDir"
OUTPUT_FILE="$SCRIPT_DIR/Gladden.AppImage"

echo "=== Gladden AppImage Creator ==="

# 1. Build the Flutter Application
echo "Building Release version..."
cd "$ROOT_DIR"
flutter pub get
flutter build linux --release

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: App build failed."
    exit 1
fi

# 2. Prepare AppDir
echo "Preparing AppDir structure..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"

cp -r "$BUILD_DIR/." "$APPDIR/usr/lib/"
ln -s "../lib/$APP_NAME" "$APPDIR/usr/bin/$APP_NAME"

# 3. Create AppRun, .desktop and icon
cat > "$APPDIR/AppRun" <<EOF
#!/bin/sh
SELF=\$(readlink -f "\$0")
HERE=\$(dirname "\$SELF")
export LD_LIBRARY_PATH="\$HERE/usr/lib:\$LD_LIBRARY_PATH"
exec "\$HERE/usr/lib/$APP_NAME" "\$@"
EOF
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Name=$DISPLAY_NAME
Exec=$APP_NAME
Icon=$APP_NAME
Type=Application
Categories=Utility;
EOF

if [ -f "$ROOT_DIR/assets/images/app_icon.png" ]; then
    cp "$ROOT_DIR/assets/images/app_icon.png" "$APPDIR/$APP_NAME.png"
fi

# 4. Download and use appimagetool
APPIMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
TOOL_PATH="$ROOT_DIR/build/appimagetool"

if [ ! -f "$TOOL_PATH" ]; then
    echo "Downloading appimagetool..."
    curl -L "$APPIMAGE_TOOL_URL" -o "$TOOL_PATH"
    chmod +x "$TOOL_PATH"
fi

# 5. Build AppImage
echo "Building final AppImage..."
export ARCH=x86_64
# Use --appimage-extract-and-run to avoid FUSE dependency on systems like Ubuntu 24.04
"$TOOL_PATH" --appimage-extract-and-run "$APPDIR" "$OUTPUT_FILE"

echo "Done! $OUTPUT_FILE created."
