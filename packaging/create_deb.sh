#!/bin/bash
set -e

# Configuration
APP_NAME="tvmax"
VERSION="1.0.0"
ARCH="amd64"
BUILD_DIR="../build/linux/x64/release/bundle"
DEB_DIR="${APP_NAME}_${VERSION}_${ARCH}"

echo "Starting DEB creation for $APP_NAME v$VERSION..."
# 1. Prepare Directory Structure
echo "Preparing directory structure..."
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/local/bin"
mkdir -p "$DEB_DIR/usr/local/lib/$APP_NAME"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/512x512/apps"

# 2. Check Build Artifacts
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found! Please run 'flutter build linux' first."
    exit 1
fi

# 3. Copy Application Files
echo "Copying application files..."
cp -r "$BUILD_DIR/"* "$DEB_DIR/usr/local/lib/$APP_NAME/"

# 4. Create Symbolic Link
echo "Creating symlink..."
ln -s "/usr/local/lib/$APP_NAME/$APP_NAME" "$DEB_DIR/usr/local/bin/$APP_NAME"

# 5. Generate Control File
echo "Generating control file..."
SIZE=$(du -s "$DEB_DIR/usr" | awk '{print $1}')
cat > "$DEB_DIR/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Section: video
Priority: optional
Architecture: $ARCH
Depends: libgtk-3-0, libmpv1 (>= 0.29.0), liblzma5, fuse
Installed-Size: $SIZE
Maintainer: TVMax Team <info@tvmax.com>
Description: A powerful media player for streaming content.
 Education project.
EOF

# 6. Create Desktop Entry
echo "Creating desktop entry..."
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
echo "Copying icon..."
if [ -f "../assets/icon/icon_master.png" ]; then
    cp "../assets/icon/icon_master.png" "$DEB_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
else
    touch "$DEB_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
fi

# 8. Build DEB Package
echo "Building .deb package..."
dpkg-deb --build "$DEB_DIR"

# Cleanup
rm -rf "$DEB_DIR"

echo "${DEB_DIR}.deb created successfully!"

