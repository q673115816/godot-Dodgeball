#!/bin/bash

# Godot Export Templates Installer
# Automatically downloads and installs the correct export templates for your Godot version.

# Configuration
GODOT_BIN="godot" # Ensure this is in your PATH or set absolute path
MIRROR_URL="https://github.com/godotengine/godot/releases/download"

# Check if Godot is installed
if ! command -v "$GODOT_BIN" &> /dev/null; then
    echo "❌ Error: '$GODOT_BIN' command not found."
    echo "Please install Godot and add it to your PATH, or update the GODOT_BIN variable in this script."
    exit 1
fi

# Get Godot version (e.g., 4.6.stable.official.89cea1439 -> 4.6.stable)
FULL_VERSION=$("$GODOT_BIN" --version)
VERSION_SHORT=$(echo "$FULL_VERSION" | grep -oE "^[0-9]+\.[0-9]+(\.[0-9]+)?\.stable")

if [ -z "$VERSION_SHORT" ]; then
    echo "⚠️  Could not detect stable version from: $FULL_VERSION"
    echo "Assuming version is 4.6.stable based on your request..."
    VERSION_SHORT="4.6.stable"
fi

# Construct download URL (GitHub Release convention)
# Format: https://github.com/godotengine/godot/releases/download/4.6-stable/Godot_v4.6-stable_export_templates.tpz
VERSION_DASH=${VERSION_SHORT//./-} # Replace dots with dashes (4.6.stable -> 4-6-stable) is WRONG for GitHub
# Correct GitHub format: 4.6-stable (tag) and Godot_v4.6-stable_export_templates.tpz (filename)
# VERSION_SHORT is usually "4.6.stable"
# We need "4.6-stable" for the tag and filename part.
TAG_VERSION=$(echo "$VERSION_SHORT" | sed 's/\.stable/-stable/')
FILENAME="Godot_v${TAG_VERSION}_export_templates.tpz"
DOWNLOAD_URL="${MIRROR_URL}/${TAG_VERSION}/${FILENAME}"

# Destination Directory (macOS/Linux standard)
# macOS: ~/Library/Application Support/Godot/export_templates/
# Linux: ~/.local/share/godot/export_templates/
if [[ "$OSTYPE" == "darwin"* ]]; then
    TEMPLATE_DIR="$HOME/Library/Application Support/Godot/export_templates/${VERSION_SHORT}"
else
    TEMPLATE_DIR="$HOME/.local/share/godot/export_templates/${VERSION_SHORT}"
fi

echo "🔍 Detected Godot Version: $VERSION_SHORT"
echo "📂 Target Directory: $TEMPLATE_DIR"
echo "⬇️  Download URL: $DOWNLOAD_URL"

# Check if already installed
if [ -d "$TEMPLATE_DIR" ] && [ "$(ls -A "$TEMPLATE_DIR")" ]; then
    echo "✅ Templates seem to be already installed in $TEMPLATE_DIR"
    read -p "Do you want to reinstall? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Create directory
mkdir -p "$TEMPLATE_DIR"

# Download
TEMP_FILE="/tmp/${FILENAME}"
echo "⏳ Downloading templates (this may take a while)..."
curl -L -# -o "$TEMP_FILE" "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    echo "❌ Download failed! Please check your internet connection or the version URL."
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "📦 Extracting templates..."
# The TPZ is a ZIP file containing a "templates" folder.
# We need to unzip it to a temporary location and move contents.
unzip -q "$TEMP_FILE" -d "/tmp/godot_templates_extract"

if [ $? -eq 0 ]; then
    # Move contents from /tmp/.../templates/* to destination
    cp -r /tmp/godot_templates_extract/templates/* "$TEMPLATE_DIR/"
    echo "✅ Installed successfully to $TEMPLATE_DIR"
else
    echo "❌ Extraction failed."
    exit 1
fi

# Cleanup
rm -f "$TEMP_FILE"
rm -rf "/tmp/godot_templates_extract"

echo "🎉 Done! You can now run ./build.sh"
