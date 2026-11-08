#!/usr/bin/env bash
# Builds ScreenCorners.app from source.
# Usage: scripts/build.sh [output-dir]   (default: ./build)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$ROOT/build}"
APP="$OUT_DIR/ScreenCorners.app"
ARCH="$(uname -m)"
MIN_MACOS="13.0"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are required: xcode-select --install" >&2
  exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
[[ -f "$ROOT/Resources/AppIcon.icns" ]] && cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/"

xcrun swiftc -O -swift-version 5 -parse-as-library \
  -target "$ARCH-apple-macos$MIN_MACOS" \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  "$ROOT"/Sources/*.swift \
  -o "$APP/Contents/MacOS/ScreenCorners"

# Ad-hoc signature so macOS treats the bundle as a proper app.
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo "Built: $APP"
