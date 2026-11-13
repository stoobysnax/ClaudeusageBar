#!/bin/bash
# Builds ClaudeUsageBar.app into ./build
set -euo pipefail
cd "$(dirname "$0")/.."

# By default, build for this Mac's chip only (works with just the Command Line Tools).
# UNIVERSAL=1 builds Apple Silicon + Intel separately and merges them with lipo.
if [[ "${UNIVERSAL:-0}" == "1" ]]; then
  BINS=()
  for T in arm64-apple-macosx13.0 x86_64-apple-macosx13.0; do
    swift build -c release --triple "$T"
    BINS+=("$(swift build -c release --triple "$T" --show-bin-path)/ClaudeUsageBar")
  done
  BIN="build/ClaudeUsageBar-universal"
  mkdir -p build
  lipo -create "${BINS[@]}" -output "$BIN"
else
  swift build -c release
  BIN="$(swift build -c release --show-bin-path)/ClaudeUsageBar"
fi
VERSION="${VERSION:-1.0}"

APP="build/ClaudeUsageBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/ClaudeUsageBar"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>ClaudeUsageBar</string>
    <key>CFBundleDisplayName</key><string>Claude Usage Bar</string>
    <key>CFBundleIdentifier</key><string>com.stoobysnax.ClaudeUsageBar</string>
    <key>CFBundleExecutable</key><string>ClaudeUsageBar</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
echo "Install:  cp -R $APP /Applications/ && open /Applications/ClaudeUsageBar.app"
