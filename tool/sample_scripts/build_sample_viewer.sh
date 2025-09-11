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

# Always change to project root.
project_root="$(git rev-parse --show-toplevel)"
cd "$project_root"


# Step 1: Ensure release_builds/ folder exists and clean its contents if not empty.
release_dir="$project_root/release_builds"
if [ ! -d "$release_dir" ]; then
  echo "[INFO] Creating release_builds/ directory at $release_dir..."
  mkdir -p "$release_dir"
elif [ "$(ls -A "$release_dir")" ]; then
  echo "[INFO] Cleaning previous contents of $release_dir..."
  rm -rf "${release_dir:?}"/*
fi

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

# Step 6: Copy APK and iOS .app files (use absolute paths).

apk_path="$project_root/build/app/outputs/flutter-apk/app-release.apk"
ios_app_path="$project_root/build/ios/iphoneos/Runner.app"

ls -lh "$project_root/build/app/outputs/flutter-apk/" || echo "[DEBUG] APK output directory not found."
ls -lh "$project_root/build/ios/iphoneos/" || echo "[DEBUG] iOS output directory not found."
if [ -f "$apk_path" ]; then
  cp "$apk_path" "$release_dir/"
  echo "[INFO] APK copied to $release_dir."
else
  echo "[WARNING] APK not found at $apk_path."
fi


if [ -d "$ios_app_path" ]; then
  cp -R "$ios_app_path" "$release_dir/"
  echo "[INFO] iOS .app bundle copied to $release_dir."
  echo "[INFO] To install on a physical device, open the project in Xcode and deploy to your device."
else
  echo "[WARNING] iOS .app bundle not found at $ios_app_path."
fi

echo "[SUCCESS] Build process completed. Artifacts are in $release_dir."
