#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Learned Importer"
EXECUTABLE="LearnedImporter"
BUILD_DIR="$PWD/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
REPO_ROOT="$(cd "$PWD/../.." && pwd)"
INSTALL_DIR="$HOME/Applications"

install_app=1
if [[ "${1:-}" == "--no-install" ]]; then
  install_app=0
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

echo "Generating app icon…"
swift make-icon.swift "$BUILD_DIR/icon-1024.png"

ICONSET="$BUILD_DIR/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$BUILD_DIR/icon-1024.png" \
    --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" "$BUILD_DIR/icon-1024.png" \
    --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "Compiling SwiftUI app…"
ARCH="$(uname -m)"
swiftc -O -parse-as-library \
  -target "${ARCH}-apple-macos13.0" \
  Sources/*.swift \
  -o "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE"

sed "s|__BLOG_REPO_PATH__|$REPO_ROOT|g" Info.plist.in > "$APP_BUNDLE/Contents/Info.plist"
plutil -lint "$APP_BUNDLE/Contents/Info.plist" >/dev/null

echo "Signing (ad hoc)…"
codesign --force --sign - "$APP_BUNDLE" >/dev/null

if [[ "$install_app" -eq 1 ]]; then
  mkdir -p "$INSTALL_DIR"
  rm -rf "$INSTALL_DIR/$APP_NAME.app"
  ditto "$APP_BUNDLE" "$INSTALL_DIR/$APP_NAME.app"
  echo "Installed: $INSTALL_DIR/$APP_NAME.app"
fi

echo "Built: $APP_BUNDLE"
echo "Blog folder: $REPO_ROOT"
