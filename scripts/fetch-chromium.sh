#!/bin/bash
# Fetch Chromium source at a specific version
# Usage: ./fetch-chromium.sh [VERSION]
# If VERSION is not provided, uses the version from ../VERSION file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CHROMIUM_DIR="$REPO_ROOT/chromium"

# Get version from argument or VERSION file
VERSION="${1:-$(cat "$REPO_ROOT/VERSION")}"

echo "=== Fetching Chromium $VERSION ==="

# Ensure depot_tools is in PATH
if ! command -v gclient &> /dev/null; then
    echo "depot_tools not found in PATH"
    echo "Run ./setup-depot-tools.sh first, then add depot_tools to PATH"
    exit 1
fi

# Create chromium directory
mkdir -p "$CHROMIUM_DIR"
cd "$CHROMIUM_DIR"

# Copy .gclient config if not exists
if [ ! -f ".gclient" ]; then
    echo "Copying .gclient configuration..."
    cp "$REPO_ROOT/build-config/.gclient" .gclient
fi

# Check if src directory exists
if [ -d "src" ]; then
    echo "Chromium source exists, syncing to version $VERSION..."
    cd src

    # Fetch latest refs
    git fetch origin

    # Try to find the tag or use the version as a branch position
    if git rev-parse "refs/tags/$VERSION" &> /dev/null; then
        git checkout "refs/tags/$VERSION"
    else
        # Try branch position format (e.g., refs/branch-heads/6834)
        BRANCH=$(echo "$VERSION" | cut -d. -f3)
        if git rev-parse "refs/branch-heads/$BRANCH" &> /dev/null; then
            git checkout "refs/branch-heads/$BRANCH"
        else
            echo "Warning: Exact version $VERSION not found, using main branch"
            git checkout main
        fi
    fi

    cd ..
else
    echo "Fetching Chromium source (this will take a while)..."
    fetch --nohooks android
fi

# Sync dependencies
echo "Syncing dependencies..."
gclient sync -D --force --reset

# Record the commit hash
cd src
COMMIT_HASH=$(git rev-parse HEAD)
echo "$COMMIT_HASH" > "$REPO_ROOT/CHROMIUM_COMMIT"
cd ..

echo ""
echo "=== Chromium source ready ==="
echo "Version: $VERSION"
echo "Commit: $COMMIT_HASH"
echo "Location: $CHROMIUM_DIR/src"
echo ""
echo "Next steps:"
echo "  1. Install build dependencies: cd src && ./build/install-build-deps.sh --android"
echo "  2. Apply patches: ../scripts/apply-patches.sh"
echo "  3. Build: ../scripts/build.sh"
