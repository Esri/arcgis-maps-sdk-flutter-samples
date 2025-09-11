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

# This script builds the Sample Viewer App for both Android and iOS in release mode,
# using environment variables defined in env.json, and places the resulting
# APK and iOS .app bundle into a release_builds/ folder at the root of the repository.
# It assumes that you have already set up your Flutter environment and have
# the necessary certificates and provisioning profiles for iOS.
# It also assumes that env.json is present at the root of the repository.
#
# Note: This script does not produce an IPA file, but generates the .app bundle for iOS.

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

apk_path="$project_root/build/app/outputs/flutter-apk/app-release.apk"
ios_app_path="$project_root/build/ios/iphoneos/Runner.app"

ls -lh "$project_root/build/app/outputs/flutter-apk/" || echo "[DEBUG] APK output directory not found."
ls -lh "$project_root/build/ios/iphoneos/" || echo "[DEBUG] iOS output directory not found."


echo "[SUCCESS] Build process completed."

# Step 6: Install to first available physical iOS/Android device.
echo "[INFO] Searching for physical iOS/Android devices for installation..."

# Find all matching physical iOS/Android devices.
device_ids=( $(flutter devices --machine | \
  jq -r '.[] | select((.targetPlatform=="ios" or .targetPlatform=="android") and (.emulator==false) and (.isSupported==true)) | .id') )

if [ ${#device_ids[@]} -eq 0 ]; then
  echo "[INFO] No physical iOS/Android device found for installation."
else
  for device_id in "${device_ids[@]}"; do
    echo "[INFO] Installing app to device: $device_id"
    flutter install -d "$device_id" --release
  done
fi
