#!/bin/bash
# Builds ClaudeUsageBar.app into ./build
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
BIN="$(swift build -c release --show-bin-path)/ClaudeUsageBar"

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
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
echo "Install:  cp -R $APP /Applications/ && open /Applications/ClaudeUsageBar.app"
