#!/bin/bash
# One-line installer for ClaudeUsageBar.
#   curl -fsSL https://raw.githubusercontent.com/stoobysnax/ClaudeusageBar/main/install.sh | bash
set -euo pipefail

if ! xcode-select -p >/dev/null 2>&1 || ! command -v swift >/dev/null 2>&1; then
  echo "Apple's Command Line Tools are needed (a free, one-time install, not the Xcode app)."
  echo "A window will pop up: click Install, wait for it to finish, then run this command again."
  xcode-select --install || true
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Downloading…"
curl -fsSL https://github.com/stoobysnax/ClaudeusageBar/archive/refs/heads/main.tar.gz | tar -xz -C "$TMP"
cd "$TMP"/ClaudeusageBar-main

echo "Building (takes a minute)…"
./scripts/build-app.sh >/dev/null

pkill -x ClaudeUsageBar 2>/dev/null || true
rm -rf /Applications/ClaudeUsageBar.app
cp -R build/ClaudeUsageBar.app /Applications/
open /Applications/ClaudeUsageBar.app
echo "Installed. Look for ✳︎ in your menu bar."
echo "If macOS asks to let 'security' use the 'Claude Code-credentials' keychain item, click Always Allow."
