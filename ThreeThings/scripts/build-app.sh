#!/bin/bash
# Builds "3 Things.app" into ./build
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${UNIVERSAL:-0}" == "1" ]]; then
  BINS=()
  for T in arm64-apple-macosx13.0 x86_64-apple-macosx13.0; do
    swift build -c release --product ThreeThings --triple "$T"
    BINS+=("$(swift build -c release --triple "$T" --show-bin-path)/ThreeThings")
  done
  BIN="build/ThreeThings-universal"
  mkdir -p build
  lipo -create "${BINS[@]}" -output "$BIN"
else
  swift build -c release --product ThreeThings
  BIN="$(swift build -c release --show-bin-path)/ThreeThings"
fi
VERSION="${VERSION:-1.0}"

APP="build/3 Things.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ThreeThings"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>3 Things</string>
    <key>CFBundleDisplayName</key><string>3 Things</string>
    <key>CFBundleIdentifier</key><string>com.stoobysnax.ThreeThings</string>
    <key>CFBundleExecutable</key><string>ThreeThings</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
