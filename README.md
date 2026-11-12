# ClaudeUsageBar

A tiny macOS menu bar app that shows your Claude plan usage:

- **Session**: the current 5-hour window
- **Week**: the 7-day window, plus the Opus/Sonnet weekly limits when you have usage there

The menu bar shows `✳︎ 23% · 41%` (session · week). Click it for progress bars and reset times. It refreshes every 2 minutes.

## Requirements

- macOS 13 or later
- Xcode or the Xcode Command Line Tools (`xcode-select --install`)
- [Claude Code](https://claude.com/claude-code) installed and logged in with your Claude Pro/Max account (run `claude` once). The app reuses that login; it never asks for your password.

## Build & run

```bash
./scripts/build-app.sh
cp -R build/ClaudeUsageBar.app /Applications/
open /Applications/ClaudeUsageBar.app
```

The first time, macOS asks whether `security` may read the **Claude Code-credentials** keychain item. Click **Always Allow**.

To start it at login, go to System Settings → General → Login Items and add ClaudeUsageBar.

## How it works

It reads Claude Code's OAuth token from the Keychain (or `~/.claude/.credentials.json`) and calls `https://api.anthropic.com/api/oauth/usage`, the same endpoint behind Claude Code's `/usage` command. That endpoint is undocumented and could change.

If you see "Login expired", run `claude` in Terminal once. Claude Code refreshes the token, and the app picks it up on its next refresh. The app deliberately doesn't refresh the token itself, because that would log Claude Code out.
