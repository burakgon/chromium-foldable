#!/bin/bash
# Create a patch from changes in the Chromium source tree
# Usage: ./create-patch.sh <patch-name> [description]
# Example: ./create-patch.sh "foldable-mode-switch" "Add desktop/mobile mode switch for foldables"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PATCHES_DIR="$REPO_ROOT/patches"
CHROMIUM_SRC="$REPO_ROOT/chromium/src"

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <patch-name> [description]"
    echo "Example: $0 foldable-mode-switch 'Add desktop/mobile mode switch'"
    exit 1
fi

PATCH_NAME="$1"
DESCRIPTION="${2:-$PATCH_NAME}"

# Check if Chromium source exists
if [ ! -d "$CHROMIUM_SRC" ]; then
    echo "Error: Chromium source not found at $CHROMIUM_SRC"
    exit 1
fi

cd "$CHROMIUM_SRC"

# Check for changes
if git diff --quiet && git diff --cached --quiet; then
    echo "No changes detected in Chromium source"
    echo ""
    echo "To create a patch:"
    echo "  1. Make your changes in $CHROMIUM_SRC"
    echo "  2. Run this script again"
    exit 1
fi

# Get next patch number
EXISTING_PATCHES=$(ls -1 "$PATCHES_DIR"/*.patch 2>/dev/null | wc -l)
PATCH_NUM=$(printf "%04d" $((EXISTING_PATCHES + 1)))

# Sanitize patch name
SAFE_NAME=$(echo "$PATCH_NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
PATCH_FILE="$PATCHES_DIR/${PATCH_NUM}-${SAFE_NAME}.patch"

echo "=== Creating patch ==="
echo "Name: $SAFE_NAME"
echo "Description: $DESCRIPTION"
echo "Output: $PATCH_FILE"

# Show what will be included
echo ""
echo "Changes to include:"
git diff --stat
git diff --cached --stat

# Create the patch
{
    echo "Subject: [PATCH] $DESCRIPTION"
    echo ""
    echo "$DESCRIPTION"
    echo ""
    echo "---"
    git diff
    git diff --cached
} > "$PATCH_FILE"

echo ""
echo "=== Patch created ==="
echo "File: $PATCH_FILE"
echo ""
echo "Next steps:"
echo "  1. Add the patch to patches/series:"
echo "     echo '${PATCH_NUM}-${SAFE_NAME}.patch' >> $PATCHES_DIR/series"
echo ""
echo "  2. Reset Chromium changes (optional, to test patch application):"
echo "     cd $CHROMIUM_SRC && git checkout ."
echo ""
echo "  3. Test applying patches:"
echo "     $SCRIPT_DIR/apply-patches.sh"
