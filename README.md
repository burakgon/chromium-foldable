# Chromium Foldable - Android Desktop ARM64 Fork

Custom Chromium build for Android foldable devices with desktop mode enhancements.

## Overview

This repository maintains a customized Chromium fork targeting **Android Desktop ARM64** with:
- Foldable device optimizations
- Desktop/mobile mode switching for foldable screens
- Extensions menu customizations for folded displays
- Upstream tracking via Chromium snapshots

**Build Platform**: Android ARM64 (arm64-v8a)
**Source**: [Android Desktop ARM64 Snapshots](https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=AndroidDesktop_arm64/)

## Repository Structure

```
chromium-foldable/
├── README.md                    # This file
├── VERSION                      # Current Chromium version
├── CHROMIUM_COMMIT              # Upstream commit hash
├── patches/                     # Customization patches
│   └── series                   # Patch application order
├── build-config/
│   ├── args.gn                  # GN build arguments
│   └── .gclient                 # depot_tools checkout config
└── scripts/
    ├── setup-depot-tools.sh     # One-time setup
    ├── fetch-chromium.sh        # Fetch source
    ├── apply-patches.sh         # Apply patches
    ├── build.sh                 # Build APK
    ├── create-patch.sh          # Create new patch
    └── update-to-version.sh     # Update Chromium version
```

## System Requirements

- **OS**: Linux (tested on Fedora 44)
- **RAM**: 32GB+ recommended (16GB minimum)
- **Disk**: 500GB+ free space
- **CPU**: 16+ cores recommended

## Quick Start

### 1. Install System Dependencies (Fedora)

```bash
sudo dnf groupinstall "Development Tools" "C Development Tools and Libraries"
sudo dnf install git python3 curl gperf bison flex ninja-build \
    nss-devel alsa-lib-devel gtk3-devel libXScrnSaver-devel \
    libdrm-devel libgbm-devel libxkbcommon-devel mesa-libGL-devel \
    cups-devel pango-devel freetype-devel
```

### 2. Setup depot_tools

```bash
./scripts/setup-depot-tools.sh
export PATH="$(pwd)/depot_tools:$PATH"
```

### 3. Fetch Chromium Source

```bash
./scripts/fetch-chromium.sh
```

This fetches the version specified in `VERSION` file. First fetch takes several hours.

### 4. Install Android Build Dependencies

```bash
cd chromium/src
./build/install-build-deps.sh --android
cd ../..
```

### 5. Apply Patches

```bash
./scripts/apply-patches.sh
```

### 6. Build

```bash
./scripts/build.sh
```

Output APK: `chromium/src/out/Release/apks/ChromePublic.apk`

## Managing Patches

### Creating a New Patch

1. Make changes in `chromium/src/`
2. Run: `./scripts/create-patch.sh "patch-name" "Description"`
3. Add patch filename to `patches/series`

### Key Source Locations

For **foldable desktop/mobile mode switching**:
- `ui/android/java/src/org/chromium/ui/base/DeviceFormFactor.java`
- `chrome/browser/ui/android/desktop_site/`
- `chrome/android/java/src/org/chromium/chrome/browser/toolbar/`

For **extensions menu customization**:
- `chrome/browser/ui/android/toolbar/`
- `chrome/browser/ui/toolbar/app_menu_model.cc`
- `chrome/android/java/src/org/chromium/chrome/browser/toolbar/ToolbarLayout.java`

## Updating to a New Chromium Version

```bash
./scripts/update-to-version.sh 133.0.6900.0
```

This will:
1. Backup existing patches
2. Fetch new Chromium version
3. Attempt to apply patches (may need rebasing)

## Build Configuration

Build settings are in `build-config/args.gn`:

```gn
target_os = "android"
target_cpu = "arm64"
is_debug = false
is_official_build = true
enable_desktop_android = true
```

## License

Chromium is licensed under the BSD license. See [Chromium License](https://chromium.googlesource.com/chromium/src/+/HEAD/LICENSE).

Custom patches in this repository are available under the same license.
