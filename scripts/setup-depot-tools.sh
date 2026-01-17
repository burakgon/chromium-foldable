#!/bin/bash
# Setup depot_tools for Chromium development
# Run this once to set up your build environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DEPOT_TOOLS_DIR="$REPO_ROOT/depot_tools"

echo "=== Setting up depot_tools ==="

# Clone depot_tools if not present
if [ -d "$DEPOT_TOOLS_DIR" ]; then
    echo "depot_tools already exists at $DEPOT_TOOLS_DIR"
    echo "Updating..."
    cd "$DEPOT_TOOLS_DIR"
    git pull
else
    echo "Cloning depot_tools..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR"
fi

# Add to PATH for this session
export PATH="$DEPOT_TOOLS_DIR:$PATH"

echo ""
echo "=== depot_tools setup complete ==="
echo ""
echo "Add depot_tools to your PATH permanently by adding this to ~/.bashrc:"
echo "  export PATH=\"$DEPOT_TOOLS_DIR:\$PATH\""
echo ""
echo "Or source this file before building:"
echo "  source $SCRIPT_DIR/setup-depot-tools.sh"
