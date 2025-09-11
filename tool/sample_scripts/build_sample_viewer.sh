#!/bin/bash -e
#
# COPYRIGHT 1995-2025 ESRI
#
# TRADE SECRETS: ESRI PROPRIETARY AND CONFIDENTIAL
# Unpublished material - all rights reserved under the
# Copyright Laws of the United States and applicable international
# laws, treaties, and conventions.
#
# For additional information, contact:
# Environmental Systems Research Institute, Inc.
# Attn: Contracts and Legal Services Department
# 380 New York Street
# Redlands, California, 92373
# USA
#
# email: contracts@esri.com
#

# Builds the Sample Viewer App for both Android and iOS in release mode.
# Uses environment variables defined in env.json (must be present at repo root)
# Outputs APK and iOS .app bundle to build/ directories
# Assumes Flutter environment, iOS certificates/profiles are set up
# Installs the built app to all connected, supported physical iOS/Android devices

set -v

# Step 1: Move to the project root directory.
project_root="$(git rev-parse --show-toplevel)"
cd "$project_root"

# Step 2: Clean previous builds.
echo "[INFO] Cleaning previous builds..."
flutter clean

# Step 3: Run build_runner to generate code.
echo "[INFO] Running build_runner to generate code..."
dart run build_runner build --delete-conflicting-outputs

# Step 4: Build Flutter APK (Android, release mode).
echo "[INFO] Building Flutter APK (Android, release mode)..."
flutter build apk --release --dart-define-from-file=env.json --no-tree-shake-icons

# Step 5: Build Flutter iOS app (release mode, for physical device).
echo "[INFO] Building Flutter iOS app (release mode, for physical device)..."
flutter build ios --release --dart-define-from-file=env.json --no-tree-shake-icons

echo "[SUCCESS] Build process completed."

# Step 6: Find and install to all matching physical iOS/Android devices.
echo "[INFO] Searching for physical iOS/Android devices for installation..."

mapfile -t device_ids < <(flutter devices --machine | jq -r '.[] | select((.targetPlatform=="ios" or .targetPlatform=="android") and (.emulator==false) and (.isSupported==true)) | .id')

if [ ${#device_ids[@]} -eq 0 ]; then
  echo "[INFO] No physical iOS/Android device found for installation."
else
  for device_id in "${device_ids[@]}"; do
    echo "[INFO] Installing app to device: $device_id"
    flutter install -d "$device_id" --release
  done
fi
