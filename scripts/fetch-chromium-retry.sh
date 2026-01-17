#!/bin/bash
# Fetch Chromium source with retry mechanism
# Handles connection drops and resumes automatically

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CHROMIUM_DIR="$REPO_ROOT/chromium"
DEPOT_TOOLS="$REPO_ROOT/depot_tools"

# Configuration
MAX_RETRIES=50
RETRY_DELAY=10
SYNC_JOBS=4

export PATH="$DEPOT_TOOLS:$PATH"

echo "=== Chromium Fetch with Retry ==="
echo "Max retries: $MAX_RETRIES"
echo "Retry delay: ${RETRY_DELAY}s"

mkdir -p "$CHROMIUM_DIR"
cd "$CHROMIUM_DIR"

# Setup .gclient if needed
if [ ! -f ".gclient" ]; then
    cp "$REPO_ROOT/build-config/.gclient" .gclient
fi

# Function to run gclient sync with retries
sync_with_retry() {
    local attempt=1
    local success=0

    while [ $attempt -le $MAX_RETRIES ] && [ $success -eq 0 ]; do
        echo ""
        echo "=== Attempt $attempt / $MAX_RETRIES ==="
        echo "Time: $(date)"

        # Run gclient sync
        if gclient sync --nohooks --no-history -j$SYNC_JOBS 2>&1 | tee -a sync.log; then
            success=1
            echo "=== Sync successful! ==="
        else
            echo "=== Sync failed, retrying in ${RETRY_DELAY}s... ==="
            sleep $RETRY_DELAY
            attempt=$((attempt + 1))

            # Increase delay for repeated failures
            if [ $attempt -gt 5 ]; then
                RETRY_DELAY=30
            fi
            if [ $attempt -gt 10 ]; then
                RETRY_DELAY=60
            fi
        fi
    done

    return $((1 - success))
}

# Check if we have a partial checkout
if [ -d "src/.git" ]; then
    echo "Found existing partial checkout, resuming..."
    sync_with_retry
else
    echo "Starting fresh checkout..."

    # First, try to clone the main repo with retries
    attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        echo ""
        echo "=== Clone attempt $attempt / $MAX_RETRIES ==="

        if [ ! -d "src" ]; then
            # Use gclient sync which handles everything
            if gclient sync --nohooks --no-history -j$SYNC_JOBS 2>&1 | tee -a sync.log; then
                echo "=== Initial sync successful! ==="
                break
            fi
        else
            # Resume with sync
            if gclient sync --nohooks --no-history -j$SYNC_JOBS 2>&1 | tee -a sync.log; then
                echo "=== Sync successful! ==="
                break
            fi
        fi

        echo "=== Failed, retrying in ${RETRY_DELAY}s... ==="
        sleep $RETRY_DELAY
        attempt=$((attempt + 1))
    done
fi

# Verify success
if [ -d "src/chrome" ]; then
    echo ""
    echo "=== Chromium source fetched successfully! ==="
    echo "Location: $CHROMIUM_DIR/src"

    # Get commit info
    cd src
    COMMIT=$(git rev-parse HEAD)
    echo "Commit: $COMMIT"
    echo "$COMMIT" > "$REPO_ROOT/CHROMIUM_COMMIT"

    echo ""
    echo "Next: Run install-build-deps.sh and apply patches"
else
    echo ""
    echo "=== Fetch incomplete ==="
    echo "Run this script again to resume"
    exit 1
fi
