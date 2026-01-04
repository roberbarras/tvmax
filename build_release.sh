#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting TVMax Build Process...${NC}"



# 0. Environment Setup (Robust Android SDK Detection)
if [ -z "$ANDROID_HOME" ]; then
    echo -e "${BLUE}🔍 ANDROID_HOME not set. Searching for SDK...${NC}"
    # Common paths
    DETECTED_SDK=""
    if [ -d "$HOME/Android/Sdk" ]; then
        DETECTED_SDK="$HOME/Android/Sdk"
    elif [ -d "$HOME/Android/sdk" ]; then
        DETECTED_SDK="$HOME/Android/sdk"
    elif [ -d "/usr/lib/android-sdk" ]; then
        DETECTED_SDK="/usr/lib/android-sdk"
    fi

    if [ -n "$DETECTED_SDK" ]; then
        export ANDROID_HOME="$DETECTED_SDK"
        export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"
        echo -e "${GREEN}✅ Found Android SDK at: $ANDROID_HOME ${NC}"
    else
        echo -e "${BLUE}❌ Could not auto-detect Android SDK.${NC}" 
        echo -e "${BLUE}Please set ANDROID_HOME in your ~/.bashrc or install the SDK.${NC}"
    fi
else
     echo -e "${GREEN}✅ ANDROID_HOME is set to: $ANDROID_HOME ${NC}"
fi

# 0.5. Pre-flight Check (Ensure Packaging Tools Exist)
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

# Move AppImages to dist
mv packaging/tvmax-full.AppImage dist/
mv packaging/tvmax-lite.AppImage dist/
echo -e "${GREEN}✅ AppImages (Full & Lite) created in dist/${NC}"

# 5. Build Android (Split APKs)
echo -e "${BLUE}🤖 Building Android APKs (Split per ABI)...${NC}"
flutter build apk --release --split-per-abi

# Move APKs to dist
echo -e "${BLUE}🚚 Moving APKs to dist/...${NC}"
# Depending on Flutter version, names might be app-armeabi-v7a-release.apk etc.
# We will check and move them.

if [ -f "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ]; then
    mv build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk dist/tvmax-armeabi-v7a-release.apk
fi

if [ -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]; then
    mv build/app/outputs/flutter-apk/app-arm64-v8a-release.apk dist/tvmax-arm64-v8a-release.apk
fi

if [ -f "build/app/outputs/flutter-apk/app-x86_64-release.apk" ]; then
    mv build/app/outputs/flutter-apk/app-x86_64-release.apk dist/tvmax-x86_64-release.apk
fi

echo -e "${GREEN}✅ Split APKs created in dist/${NC}"

echo -e "${GREEN}🎉 All builds completed successfully! Files are in 'dist/' folder.${NC}"
ls -lh dist/
