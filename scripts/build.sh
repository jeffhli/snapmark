#!/bin/bash
set -euo pipefail

APP_NAME="SnapMark"
BUILD_DIR=".build/release"
APP_BUNDLE="build/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

echo "Building ${APP_NAME} (release)..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp "${BUILD_DIR}/${APP_NAME}" "${MACOS}/${APP_NAME}"
cp Resources/Info.plist "${CONTENTS}/Info.plist"

# Copy asset files if they exist
cp Resources/Assets/*.png "${RESOURCES}/" 2>/dev/null || true

# Ad-hoc code sign with entitlements
codesign --force --sign - --entitlements Resources/SnapMark.entitlements "${APP_BUNDLE}"

echo "Done: ${APP_BUNDLE}"
echo "Run with: open ${APP_BUNDLE}"
