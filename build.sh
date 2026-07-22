#!/bin/bash
# Builds "Caffeine Widget.app" from source and installs it to ~/Applications.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="/Applications/Caffeine Widget.app"
MACOS="$APP/Contents/MacOS"
RES="$APP/Contents/Resources"
BUILD="$SRC_DIR/.build"

echo "🧹 Cleaning old build..."
rm -rf "$APP" "$BUILD"
mkdir -p "$MACOS" "$RES" "$BUILD"

echo "🎨 Generating app icon..."
swiftc -O "$SRC_DIR/makeicon.swift" -o "$BUILD/makeicon" -framework AppKit
"$BUILD/makeicon" "$BUILD/icon_1024.png"

ICONSET="$BUILD/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
    sips -z "$s" "$s"       "$BUILD/icon_1024.png" --out "$ICONSET/icon_${s}x${s}.png"      >/dev/null
    sips -z "$((s*2))" "$((s*2))" "$BUILD/icon_1024.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$RES/AppIcon.icns"

echo "🔨 Compiling app..."
swiftc -O "$SRC_DIR/main.swift" -o "$MACOS/CaffeineWidget" -framework AppKit

echo "📦 Packaging..."
cp "$SRC_DIR/Info.plist" "$APP/Contents/Info.plist"

# Ad-hoc code signature so macOS lets it run without Gatekeeper fuss.
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "✅ Built: $APP"
