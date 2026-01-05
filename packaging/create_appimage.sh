#!/bin/bash
set -e

# Configuration
APP_NAME="tvmax"
BUILD_DIR="../build/linux/x64/release/bundle"
APP_DIR="AppDir"
ICON_PATH="../assets/icon/icon_master.png"

echo "🚀 Starting AppImage creation for $APP_NAME..."

# 1. Prepare AppDir Structure
rm -f *.AppImage # Clean up old artifacts (including legacy names)
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/usr/bin"

# 2. Copy Build Artifacts
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Build directory not found! Please run 'flutter build linux' first."
    exit 1
fi
echo "📦 Copying build files..."
cp -r "$BUILD_DIR/"* "$APP_DIR/usr/bin/"

# 3. Copy Metadata
echo "📄 Copying metadata..."
cp "AppRun" "$APP_DIR/"
chmod +x "$APP_DIR/AppRun"
cp "$APP_NAME.desktop" "$APP_DIR/"

# 4. Handle Icon (Use generated or placeholder)
if [ -f "$ICON_PATH" ]; then
    cp "$ICON_PATH" "$APP_DIR/$APP_NAME.png"
else
    # Create dummy icon if missing
    echo "⚠️ Icon not found. Creating placeholder."
    convert -size 512x512 xc:orange "$APP_DIR/$APP_NAME.png" 2>/dev/null || touch "$APP_DIR/$APP_NAME.png"
fi

# 5. Download AppImageTool and Runtime (if needed)
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    echo "⬇️ Downloading appimagetool..."
    wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

if [ ! -f "runtime-x86_64" ]; then
    echo "⬇️ Downloading AppImage runtime..."
    wget -q https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64
fi

# 6. Generate AppImage
# 6. Generate Versions (Lite and Full)
echo "🔨 Generating AppImages..."

# Define variations
declare -A VARIATIONS
VARIATIONS=( ["full"]="with_tools" ["lite"]="no_tools" )

for VARIANT in "${!VARIATIONS[@]}"; do
    TYPE=${VARIATIONS[$VARIANT]}
    APP_DIR_VAR="${APP_DIR}_$VARIANT"
    
    echo "Creating $VARIANT version..."
    rm -rf "$APP_DIR_VAR"
    cp -r "$APP_DIR" "$APP_DIR_VAR"
    
    if [ "$TYPE" == "no_tools" ]; then
        echo "🧹 Removing bundled tools for Lite version..."
        rm -rf "$APP_DIR_VAR/usr/bin/bin"
    fi
    
    # Generate AppImage
    ARCH=x86_64 ./appimagetool-x86_64.AppImage --runtime-file runtime-x86_64 --no-appstream "$APP_DIR_VAR" "$APP_NAME-$VARIANT.AppImage"
    echo "✅ TVMax-$VARIANT.AppImage created."
    
    rm -rf "$APP_DIR_VAR"
done

# Cleanup standard AppDir
rm -rf "$APP_DIR"

echo "✅ All builds completed!"
