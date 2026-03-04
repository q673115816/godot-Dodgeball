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
BUILD_DIR="builds"

# Platform name mapping (user-friendly name -> export preset name)
declare -A PLATFORM_MAP
PLATFORM_MAP["Web"]="Web"
PLATFORM_MAP["Windows"]="Windows Desktop"
PLATFORM_MAP["macOS"]="macOS"
PLATFORM_MAP["Linux"]="Linux/X11"
PLATFORM_MAP["Android"]="Android"

# Platforms defined in export_presets.cfg
PLATFORMS=("Web" "Windows Desktop" "macOS" "Linux/X11" "Android")

mkdir -p "$BUILD_DIR/web"
mkdir -p "$BUILD_DIR/windows"
mkdir -p "$BUILD_DIR/macos"
mkdir -p "$BUILD_DIR/linux"
mkdir -p "$BUILD_DIR/android"

echo "🚀 Starting build process..."

build_platform() {
    local platform=$1
    local preset_name="${PLATFORM_MAP[$platform]}"

    # If no mapping found, use the platform name as-is
    if [ -z "$preset_name" ]; then
        preset_name="$platform"
    fi

    echo "📦 Building for $preset_name..."

    # Run Godot export
    # --path: Specify the project path
    # --headless: Run without window
    # --export-release: Export in release mode
    "$GODOT_BIN" --path "$PROJECT_PATH" --headless --export-release "$preset_name"

    if [ $? -eq 0 ]; then
        echo "✅ $preset_name build successful!"
    else
        echo "❌ $preset_name build failed!"
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
