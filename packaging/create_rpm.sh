#!/bin/bash
set -e

# Configuration
APP_NAME="tvmax"
VERSION="1.0.0"
RELEASE="1"
ARCH="x86_64"
BUILD_DIR="../build/linux/x64/release/bundle"
RPM_BUILD_ROOT="${PWD}/rpmbuild"

echo "Starting RPM creation for $APP_NAME v$VERSION..."

# 1. Prepare RPM Build Structure
rm -rf "$RPM_BUILD_ROOT"
mkdir -p "$RPM_BUILD_ROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p "$RPM_BUILD_ROOT/BUILDROOT/${APP_NAME}-${VERSION}-${RELEASE}.${ARCH}/usr/local/bin"
mkdir -p "$RPM_BUILD_ROOT/BUILDROOT/${APP_NAME}-${VERSION}-${RELEASE}.${ARCH}/usr/local/lib/$APP_NAME"
mkdir -p "$RPM_BUILD_ROOT/BUILDROOT/${APP_NAME}-${VERSION}-${RELEASE}.${ARCH}/usr/share/applications"
mkdir -p "$RPM_BUILD_ROOT/BUILDROOT/${APP_NAME}-${VERSION}-${RELEASE}.${ARCH}/usr/share/icons/hicolor/512x512/apps"

DEST_DIR="$RPM_BUILD_ROOT/BUILDROOT/${APP_NAME}-${VERSION}-${RELEASE}.${ARCH}"

# 2. Check Build Artifacts
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found! Please run 'flutter build linux' first."
    exit 1
fi

# 3. Copy Files to Build Root
echo "Copying files to build root..."
cp -r "$BUILD_DIR/"* "$DEST_DIR/usr/local/lib/$APP_NAME/"

# 4. Create Symbolic Link
ln -s "/usr/local/lib/$APP_NAME/$APP_NAME" "$DEST_DIR/usr/local/bin/$APP_NAME"

# 5. Create Desktop Entry
cat > "$DEST_DIR/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Name=TVMax
Comment=Stream your favorite content
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Video;AudioVideo;
EOF

# 6. Copy Icon
ICON_SRC="../assets/icon/icon_master.png"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$DEST_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
else
    touch "$DEST_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
fi

# 7. Create SPEC File
echo "Generating SPEC file..."
cat > "$RPM_BUILD_ROOT/SPECS/$APP_NAME.spec" <<EOF
Name:       $APP_NAME
Version:    $VERSION
Release:    $RELEASE
Summary:    TVMax Media Player
License:    MIT
Group:      Applications/Multimedia
BuildArch:  $ARCH
Requires:   gtk3, mpv-libs, xz-libs, glib2

%description
A powerful media player for streaming content.
Education project.

%files
/usr/local/bin/$APP_NAME
/usr/local/lib/$APP_NAME
/usr/share/applications/$APP_NAME.desktop
/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png

%post
# Post-installation script (optional, e.g., update icon cache)
/usr/bin/update-desktop-database &> /dev/null || :

%postun
/usr/bin/update-desktop-database &> /dev/null || :

%changelog
* $(date "+%a %b %d %Y") TVMax Team <info@tvmax.com> - $VERSION-$RELEASE
- Release version $VERSION
EOF

# 8. Run RPMBuild
echo "Running rpmbuild..."
rpmbuild --define "_topdir $RPM_BUILD_ROOT" \
         --buildroot "$DEST_DIR" \
         -bb "$RPM_BUILD_ROOT/SPECS/$APP_NAME.spec"

# 9. Move Artifact
mv "$RPM_BUILD_ROOT/RPMS/$ARCH/"*.rpm .
echo "RPM created successfully."

# Cleanup
rm -rf "$RPM_BUILD_ROOT"
