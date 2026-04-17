#!/bin/bash
set -euo pipefail

APP_NAME="SnapMark"
BUILD_CONFIGURATION="${1:-${BUILD_CONFIGURATION:-release}}"
BUILD_DIR=".build/${BUILD_CONFIGURATION}"
APP_BUNDLE="build/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
DEFAULT_SIGN_IDENTITY="SnapMark Local Code Signing"
SIGN_IDENTITY="${SIGN_IDENTITY:-$DEFAULT_SIGN_IDENTITY}"

echo "Building ${APP_NAME} (${BUILD_CONFIGURATION})..."
swift build -c "$BUILD_CONFIGURATION" --product "$APP_NAME"

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp "${BUILD_DIR}/${APP_NAME}" "${MACOS}/${APP_NAME}"
cp Resources/Info.plist "${CONTENTS}/Info.plist"

# Copy asset files if they exist
cp Resources/Assets/*.png "${RESOURCES}/" 2>/dev/null || true

# Copy app icon
cp Resources/AppIcon.icns "${RESOURCES}/AppIcon.icns" 2>/dev/null || true

if [[ "$SIGN_IDENTITY" != "-" ]] && ! security find-identity -p codesigning -v | grep -Fq "\"$SIGN_IDENTITY\""; then
	echo "Signing identity '$SIGN_IDENTITY' was not found. Falling back to ad-hoc signing."
	SIGN_IDENTITY="-"
fi

if [[ "$SIGN_IDENTITY" == "-" ]]; then
	echo "Warning: using ad-hoc signing."
	echo "macOS may ask for Screen Recording permission again after each rebuild because"
	echo "the app identity changes when the bundle is re-signed ad-hoc."
	echo "Set SIGN_IDENTITY to an Apple Development certificate to keep a stable identity."
else
	echo "Signing with identity: $SIGN_IDENTITY"
fi

codesign --force --sign "$SIGN_IDENTITY" --entitlements Resources/SnapMark.entitlements "${APP_BUNDLE}"

echo "Done: ${APP_BUNDLE}"
echo "Run with: open ${APP_BUNDLE}"
