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
# Note: This script does not produce an IPA file, but generate the .app bundle for iOS.

# Function to print error and exit
die() {
  echo "[ERROR] $1" >&2
  exit 1
}


# Always change to project root.
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$PROJECT_ROOT" || die "Failed to change to project root directory."


# Step 1: Ensure release_builds/ folder exists and clean its contents if not empty.
RELEASE_DIR="$PROJECT_ROOT/release_builds"
if [ ! -d "$RELEASE_DIR" ]; then
  echo "[INFO] Creating release_builds/ directory at $RELEASE_DIR..."
  mkdir -p "$RELEASE_DIR" || die "Failed to create release_builds directory."
elif [ "$(ls -A "$RELEASE_DIR")" ]; then
  echo "[INFO] Cleaning previous contents of $RELEASE_DIR..."
  rm -rf "$RELEASE_DIR"/* || die "Failed to clean release_builds directory."
fi

# Step 2: Clean previous builds.
echo "[INFO] Cleaning previous builds..."
flutter clean || die "flutter clean failed."


# Step 3: Run build_runner to generate code.
echo "[INFO] Running build_runner to generate code..."
dart run build_runner build --delete-conflicting-outputs || die "build_runner failed."

# Step 4: Build Flutter APK (Android, release mode).
echo "[INFO] Building Flutter APK (Android, release mode)..."
flutter build apk --release --dart-define-from-file=env.json --no-tree-shake-icons || die "Android APK build failed."

# Step 5: Build Flutter iOS app (release mode, for physical device).
echo "[INFO] Building Flutter iOS app (release mode, for physical device)..."
flutter build ios --release --dart-define-from-file=env.json --no-tree-shake-icons || die "iOS app build failed."

# Step 6: Copy APK and iOS .app files (use absolute paths).
APK_PATH="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
IOS_APP_PATH="$PROJECT_ROOT/build/ios/iphoneos/Runner.app"



ls -lh "$PROJECT_ROOT/build/app/outputs/flutter-apk/" || echo "[DEBUG] APK output directory not found."
ls -lh "$PROJECT_ROOT/build/ios/iphoneos/" || echo "[DEBUG] iOS output directory not found."

if [ -f "$APK_PATH" ]; then
  cp "$APK_PATH" "$RELEASE_DIR/" || die "Failed to copy APK."
  echo "[INFO] APK copied to $RELEASE_DIR."
else
  echo "[WARNING] APK not found at $APK_PATH."
fi

if [ -d "$IOS_APP_PATH" ]; then
  cp -R "$IOS_APP_PATH" "$RELEASE_DIR/" || die "Failed to copy iOS .app bundle."
  echo "[INFO] iOS .app bundle copied to $RELEASE_DIR."
  echo "[INFO] To install on a physical device, open the project in Xcode and deploy to your device."

else
  echo "[WARNING] iOS .app bundle not found at $IOS_APP_PATH."
fi

echo "[SUCCESS] Build process completed. Artifacts are in $RELEASE_DIR."
