#!/bin/bash
# Update to a new Chromium version and attempt to rebase patches
# Usage: ./update-to-version.sh <new-version>
# Example: ./update-to-version.sh 133.0.6900.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CHROMIUM_SRC="$REPO_ROOT/chromium/src"
PATCHES_DIR="$REPO_ROOT/patches"
SERIES_FILE="$PATCHES_DIR/series"
VERSION_FILE="$REPO_ROOT/VERSION"

# Check arguments
if [ -z "$1" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    echo "Usage: $0 <new-version>"
    echo "Current version: $CURRENT_VERSION"
    echo ""
    echo "Find available versions at:"
    echo "  https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=AndroidDesktop_arm64/"
    echo "  https://chromiumdash.appspot.com/releases?platform=Android"
    exit 1
fi

NEW_VERSION="$1"
OLD_VERSION=$(cat "$VERSION_FILE")

echo "=== Updating Chromium ==="
echo "From: $OLD_VERSION"
echo "To:   $NEW_VERSION"
echo ""

# Check if Chromium source exists
if [ ! -d "$CHROMIUM_SRC" ]; then
    echo "Chromium source not found. Fetching fresh..."
    echo "$NEW_VERSION" > "$VERSION_FILE"
    "$SCRIPT_DIR/fetch-chromium.sh"
    exit 0
fi

# Backup current patches directory
BACKUP_DIR="$REPO_ROOT/patches.backup.$(date +%Y%m%d%H%M%S)"
echo "Backing up patches to $BACKUP_DIR"
cp -r "$PATCHES_DIR" "$BACKUP_DIR"

# Reset any local changes in Chromium source
cd "$CHROMIUM_SRC"
echo "Resetting Chromium source..."
git checkout .
git clean -fd

# Update to new version
echo "$NEW_VERSION" > "$VERSION_FILE"
cd "$REPO_ROOT"
"$SCRIPT_DIR/fetch-chromium.sh" "$NEW_VERSION"

# Try to apply patches
echo ""
echo "=== Attempting to apply patches to new version ==="
if "$SCRIPT_DIR/apply-patches.sh"; then
    echo ""
    echo "=== Update successful ==="
    echo "All patches applied cleanly to $NEW_VERSION"
    echo ""
    echo "You can remove the backup: rm -rf $BACKUP_DIR"
else
    echo ""
    echo "=== Some patches failed ==="
    echo "Patch backup saved at: $BACKUP_DIR"
    echo ""
    echo "To fix failed patches:"
    echo "  1. Apply each patch manually"
    echo "  2. Make necessary adjustments for API changes"
    echo "  3. Recreate the patch: ./create-patch.sh <name> <description>"
    echo "  4. Update patches/series with new patch filename"
fi

echo ""
echo "Updated to Chromium $NEW_VERSION"
echo "Commit hash: $(cat "$REPO_ROOT/CHROMIUM_COMMIT")"
