#!/bin/bash
# Packages build/ClaudeUsageBar.app into build/ClaudeUsageBar.dmg (drag-to-Applications installer)
set -euo pipefail
cd "$(dirname "$0")/.."

STAGE="build/dmg"
rm -rf "$STAGE" build/ClaudeUsageBar.dmg
mkdir -p "$STAGE"
cp -R build/ClaudeUsageBar.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"

hdiutil create -volname "Claude Usage Bar" -srcfolder "$STAGE" \
  -ov -format UDZO build/ClaudeUsageBar.dmg
echo "Built build/ClaudeUsageBar.dmg"
