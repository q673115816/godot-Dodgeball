#!/bin/bash

# Godot Dodgeball Game Build Script for Windows
# Usage: ./build.sh [platform]
# If no platform is specified, builds for all configured platforms.

set -e  # Exit on error

# Configuration
GODOT_BIN="C:/Users/Administrator/AppData/Local/Microsoft/WinGet/Links/godot_console.exe"  # Godot console version for headless export
# If godot_console.exe is not found, you can try:
# GODOT_BIN="godot.exe"

# Directories
PROJECT_PATH="game"
BUILD_DIR="builds"

# Check if Godot is installed
if ! [ -f "$GODOT_BIN" ]; then
    echo "❌ Error: Godot console executable not found at: $GODOT_BIN"
    echo ""
    echo "Please install Godot Engine and ensure godot_console.exe is available."
    echo "Download from: https://godotengine.org/download/"
    echo ""
    echo "If you have Godot installed elsewhere, update the GODOT_BIN variable in this script."
    exit 1
fi

# Platform name mapping function (user-friendly name -> export preset name)
get_preset_name() {
    case "$1" in
        "Web") echo "Web" ;;
        "Windows") echo "Windows Desktop" ;;
        "macOS") echo "macOS" ;;
        "Linux") echo "Linux/X11" ;;
        "Android") echo "Android" ;;
        *) echo "$1" ;;
    esac
}

# Platforms defined in export_presets.cfg
PLATFORMS=("Web" "Windows Desktop" "macOS" "Linux/X11" "Android")

# Create build directories
mkdir -p "$BUILD_DIR/web"
mkdir -p "$BUILD_DIR/windows"
mkdir -p "$BUILD_DIR/macos"
mkdir -p "$BUILD_DIR/linux"
mkdir -p "$BUILD_DIR/android"

echo "🚀 Starting build process..."
echo "📦 Godot version: $($GODOT_BIN --version 2>/dev/null || echo 'Unknown')"
echo ""

build_platform() {
    local platform=$1
    local preset_name=$(get_preset_name "$platform")

    # If no mapping found, use the platform name as-is
    if [ -z "$preset_name" ]; then
        preset_name="$platform"
    fi

    echo "📦 Building for $preset_name..."
    echo "   Output directory: $BUILD_DIR/$(echo $platform | tr '[:upper:]' '[:lower:]' | tr '/' '_')"

    # Run Godot export
    # --path: Specify the project path
    # --headless: Run without window (requires godot_console.exe on Windows)
    # --export-release: Export in release mode
    if "$GODOT_BIN" --path "$PROJECT_PATH" --headless --export-release "$preset_name"; then
        echo "✅ $preset_name build successful!"
        echo ""
        return 0
    else
        local exit_code=$?
        echo "❌ $preset_name build failed! (Exit code: $exit_code)"
        echo ""
        echo "💡 If you see 'Cannot find file at ...godot_console.exe' error:"
        echo "   - Make sure godot_console.exe exists at the path specified in GODOT_BIN"
        echo "   - Or try using godot.exe instead (remove --headless flag)"
        echo ""
        echo "💡 If you see '指定路径不存在导出模板' error:"
        echo "   - Open Godot Editor"
        echo "   - Go to: Editor -> Manage Export Templates"
        echo "   - Download and install templates for version 4.6.1.stable"
        echo "   - See INSTALL_TEMPLATES.md for detailed instructions"
        echo ""
        return 1
    fi
}

# Check if a specific platform was requested
if [ -n "$1" ]; then
    if build_platform "$1"; then
        echo "🎉 Build completed successfully!"
        exit 0
    else
        echo "❌ Build failed!"
        exit 1
    fi
else
    # Build all platforms
    local success_count=0
    local total_count=${#PLATFORMS[@]}

    for platform in "${PLATFORMS[@]}"; do
        if build_platform "$platform"; then
            ((success_count++))
        fi
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Build Summary: $success_count/$total_count successful"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ $success_count -eq $total_count ]; then
        echo "🎉 All builds completed successfully!"
        exit 0
    else
        echo "⚠️  Some builds failed. Please check the errors above."
        exit 1
    fi
fi
