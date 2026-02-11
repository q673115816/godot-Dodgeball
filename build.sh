#!/bin/bash

# Godot Dodgeball Game Build Script
# Usage: ./build.sh [platform]
# If no platform is specified, builds for all configured platforms.

# Configuration
GODOT_BIN="godot" # Assumes 'godot' is in your PATH. If not, set the full path here.
# For macOS, it might be:
# GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"

# Directories
PROJECT_PATH="game"
WEB_BUILD_DIR="apps/web"
OTHER_BUILD_DIR="game/builds"

# Platforms defined in export_presets.cfg
PLATFORMS=("Web" "Windows Desktop" "macOS" "Linux/X11" "Android")

# Create build directories
mkdir -p "$WEB_BUILD_DIR"
mkdir -p "$OTHER_BUILD_DIR/windows"
mkdir -p "$OTHER_BUILD_DIR/macos"
mkdir -p "$OTHER_BUILD_DIR/linux"
mkdir -p "$OTHER_BUILD_DIR/android"

echo "🚀 Starting build process..."

build_platform() {
    local platform=$1
    echo "📦 Building for $platform..."
    
    # Run Godot export
    # --path: Specify the project path
    # --headless: Run without window
    # --export-release: Export in release mode
    "$GODOT_BIN" --path "$PROJECT_PATH" --headless --export-release "$platform"
    
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

echo "🎉 Build process completed."
