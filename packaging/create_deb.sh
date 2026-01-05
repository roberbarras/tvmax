#!/bin/bash
set -e

# Configuration
APP_NAME="tvmax"
VERSION="1.0.0"
ARCH="amd64"
BUILD_DIR="../build/linux/x64/release/bundle"
DEB_DIR="${APP_NAME}_${VERSION}_${ARCH}"

echo "🚀 Starting DEB creation for $APP_NAME v$VERSION..."

# 1. Prepare Directory Structure
echo "📁 Preparing directory structure..."
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/local/bin"
mkdir -p "$DEB_DIR/usr/local/lib/$APP_NAME"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/512x512/apps"

# 2. Check Build Artifacts
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Build directory not found! Please run 'flutter build linux' first."
    exit 1
fi

# 3. Copy Application Files
echo "📦 Copying application files..."
cp -r "$BUILD_DIR/"* "$DEB_DIR/usr/local/lib/$APP_NAME/"

# 4. Create Symbolic Link
echo "🔗 Creating symlink..."
ln -s "/usr/local/lib/$APP_NAME/$APP_NAME" "$DEB_DIR/usr/local/bin/$APP_NAME"

# 5. Create Control File
echo "📄 Creating control file..."
cat > "$DEB_DIR/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: TVMax Team
Depends: libgtk-3-0, libglib2.0-0, liblzma5, libmpv1, mpv
Installed-Size: $(du -s "$DEB_DIR/usr" | cut -f1)
Priority: optional
Section: video
Description: TVMax Media Player
 A powerful media player for streaming content.
 Education project.
EOF

# 6. Create Desktop Entry
echo "🖥️  Creating desktop entry..."
cat > "$DEB_DIR/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Name=TVMax
Comment=Stream your favorite content
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Video;AudioVideo;
EOF

# 7. Copy Icon
echo "🎨 Copying icon..."
ICON_SRC="../assets/icon/icon_master.png"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$DEB_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
else
    echo "⚠️  Icon master not found, looking for alternative..."
    # Fallback to creating a dummy if needed, but assets should exist
    touch "$DEB_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
fi

# 8. Build DEB Package
echo "🔨 Building .deb package..."
dpkg-deb --build "$DEB_DIR"

# Cleanup
rm -rf "$DEB_DIR"

echo "✅ ${DEB_DIR}.deb created successfully!"
