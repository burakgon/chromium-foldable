#!/bin/bash
# Apply patches from patches/ directory to Chromium source
# Reads patch order from patches/series file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PATCHES_DIR="$REPO_ROOT/patches"
CHROMIUM_SRC="$REPO_ROOT/chromium/src"
SERIES_FILE="$PATCHES_DIR/series"

echo "=== Applying patches ==="

# Check if Chromium source exists
if [ ! -d "$CHROMIUM_SRC" ]; then
    echo "Error: Chromium source not found at $CHROMIUM_SRC"
    echo "Run ./fetch-chromium.sh first"
    exit 1
fi

# Check if series file exists
if [ ! -f "$SERIES_FILE" ]; then
    echo "Error: patches/series file not found"
    exit 1
fi

cd "$CHROMIUM_SRC"

# Count patches
PATCH_COUNT=0
APPLIED_COUNT=0

# Read patches from series file (skip comments and empty lines)
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    PATCH_FILE="$PATCHES_DIR/$line"
    PATCH_COUNT=$((PATCH_COUNT + 1))

    if [ ! -f "$PATCH_FILE" ]; then
        echo "Warning: Patch file not found: $line"
        continue
    fi

    echo "Applying: $line"

    # Try to apply the patch
    if git apply --check "$PATCH_FILE" 2>/dev/null; then
        git apply "$PATCH_FILE"
        APPLIED_COUNT=$((APPLIED_COUNT + 1))
        echo "  Success"
    else
        # Try with 3-way merge
        echo "  Attempting 3-way merge..."
        if git apply --3way "$PATCH_FILE"; then
            APPLIED_COUNT=$((APPLIED_COUNT + 1))
            echo "  Success (with merge)"
        else
            echo "  FAILED - patch may need rebasing"
            echo ""
            echo "To rebase this patch manually:"
            echo "  1. cd $CHROMIUM_SRC"
            echo "  2. Apply changes manually"
            echo "  3. Run: ../scripts/create-patch.sh '$line' 'your description'"
        fi
    fi
done < "$SERIES_FILE"

echo ""
echo "=== Patch application complete ==="
echo "Applied: $APPLIED_COUNT / $PATCH_COUNT patches"

if [ "$PATCH_COUNT" -eq 0 ]; then
    echo ""
    echo "No patches defined yet. To add patches:"
    echo "  1. Make changes in chromium/src/"
    echo "  2. Run: ./scripts/create-patch.sh 'patch-name' 'description'"
    echo "  3. Add patch filename to patches/series"
fi
