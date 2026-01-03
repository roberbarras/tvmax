#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting TVMax Build Process...${NC}"


# 0. Pre-flight Check (Ensure Packaging Tools Exist)
echo -e "${BLUE}🔍 Checking packaging tools...${NC}"
APPIMAGE_TOOL="packaging/appimagetool-x86_64.AppImage"
RUNTIME_FILE="packaging/runtime-x86_64"

if [ ! -f "$APPIMAGE_TOOL" ]; then
    echo -e "${BLUE}⬇️ Downloading appimagetool...${NC}"
    wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O "$APPIMAGE_TOOL"
    chmod +x "$APPIMAGE_TOOL"
fi

if [ ! -f "$RUNTIME_FILE" ]; then
    echo -e "${BLUE}⬇️ Downloading AppImage runtime...${NC}"
    wget -q https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64 -O "$RUNTIME_FILE"
fi

if [ -f "$APPIMAGE_TOOL" ] && [ -f "$RUNTIME_FILE" ]; then
    echo -e "${GREEN}✅ Packaging tools ready.${NC}"
else
    echo -e "${GREEN}⚠️ Warning: Tools not found. The script will try to use cached versions or download them later.${NC}"
fi

# 1. Clean
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean
rm -rf dist/
mkdir -p dist/

# 2. Get Dependencies
echo -e "${BLUE}📦 getting dependencies...${NC}"
flutter pub get

# 3. Build Linux
echo -e "${BLUE}🐧 Building Linux Release...${NC}"
flutter config --enable-linux-desktop
flutter build linux --release

# 4. Create AppImage
echo -e "${BLUE}📦 Packaging AppImage...${NC}"
cd packaging
chmod +x create_appimage.sh
./create_appimage.sh
cd ..

# Move AppImage to dist
mv packaging/tvmax.AppImage dist/
echo -e "${GREEN}✅ AppImage created in dist/tvmax.AppImage${NC}"

# 5. Build Android (Universal APK)
echo -e "${BLUE}🤖 Building Android APK (Universal)...${NC}"
flutter build apk --release

# Move APK to dist
mv build/app/outputs/flutter-apk/app-release.apk dist/tvmax-release.apk
echo -e "${GREEN}✅ Universal APK created in dist/tvmax-release.apk${NC}"

echo -e "${GREEN}🎉 All builds completed successfully! Files are in 'dist/' folder.${NC}"
ls -lh dist/
