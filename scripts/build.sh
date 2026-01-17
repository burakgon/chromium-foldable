#!/bin/bash
# Build Chromium Android Desktop ARM64
# Usage: ./build.sh [target]
# Default target: chrome_public_apk

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CHROMIUM_SRC="$REPO_ROOT/chromium/src"
OUT_DIR="out/Release"
TARGET="${1:-chrome_public_apk}"

echo "=== Building Chromium Android Desktop ARM64 ==="
echo "Target: $TARGET"

# Check if Chromium source exists
if [ ! -d "$CHROMIUM_SRC" ]; then
    echo "Error: Chromium source not found at $CHROMIUM_SRC"
    echo "Run ./fetch-chromium.sh first"
    exit 1
fi

# Ensure depot_tools is in PATH
if ! command -v gn &> /dev/null; then
    echo "depot_tools not found in PATH"
    echo "Run: source ./setup-depot-tools.sh"
    exit 1
fi

cd "$CHROMIUM_SRC"

# Create output directory and copy args.gn
if [ ! -d "$OUT_DIR" ]; then
    echo "Creating build directory..."
    mkdir -p "$OUT_DIR"
fi

# Copy args.gn if not present or if source is newer
if [ ! -f "$OUT_DIR/args.gn" ] || [ "$REPO_ROOT/build-config/args.gn" -nt "$OUT_DIR/args.gn" ]; then
    echo "Copying build configuration..."
    cp "$REPO_ROOT/build-config/args.gn" "$OUT_DIR/args.gn"
fi

# Run GN to generate ninja files
echo "Generating build files..."
gn gen "$OUT_DIR"

# Get number of CPU cores for parallel build
JOBS=$(nproc)
echo "Building with $JOBS parallel jobs..."

# Build using autoninja (handles job limits automatically)
autoninja -C "$OUT_DIR" "$TARGET"

echo ""
echo "=== Build complete ==="

# Check for APK
APK_PATH="$OUT_DIR/apks/ChromePublic.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "APK: $APK_PATH ($APK_SIZE)"
    echo ""
    echo "Install with: adb install -r $CHROMIUM_SRC/$APK_PATH"
fi
