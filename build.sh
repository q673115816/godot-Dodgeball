#!/bin/bash

# Godot Dodgeball Game Build Script
# Usage: ./build.sh [platform]
# If no platform is specified, builds for all configured platforms.

# Configuration
GODOT_BIN="godot" # Assumes 'godot' is in your PATH. If not, set the full path here.
# For macOS, it might be:
# GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"

BUILD_DIR="./builds"

# Platforms defined in export_presets.cfg
PLATFORMS=("Web" "Windows Desktop" "macOS" "Linux/X11" "Android")

# Create build directories
mkdir -p "$BUILD_DIR/web"
mkdir -p "$BUILD_DIR/windows"
mkdir -p "$BUILD_DIR/macos"
mkdir -p "$BUILD_DIR/linux"
mkdir -p "$BUILD_DIR/android"

echo "🚀 Starting build process..."

build_platform() {
    local platform=$1
    echo "📦 Building for $platform..."
    
    # Run Godot export
    # --headless: Run without window
    # --export-release: Export in release mode
    "$GODOT_BIN" --headless --export-release "$platform"
    
    if [ $? -eq 0 ]; then
        echo "✅ $platform build successful!"
    else
        echo "❌ $platform build failed!"
        return 1
    fi
}

# Check if a specific platform was requested
if [ -n "$1" ]; then
    build_platform "$1"
else
    # Build all platforms
    for platform in "${PLATFORMS[@]}"; do
        build_platform "$platform"
    done
fi

echo "🎉 Build process completed. Check the '$BUILD_DIR' directory."
