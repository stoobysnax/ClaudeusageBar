# ClaudeUsageBar

A tiny macOS menu bar app that shows your Claude plan usage:

- **Session**: the current 5-hour window
- **Week**: the 7-day window, plus the Opus/Sonnet weekly limits when you have usage there

The menu bar shows `✳︎ 23% · 41%` (session · week). Click it for progress bars and reset times. It refreshes every 2 minutes.

## Install

1. Download **ClaudeUsageBar.dmg** from the [latest release](https://github.com/stoobysnax/ClaudeusageBar/releases/latest).
2. Open it and drag **ClaudeUsageBar** into **Applications**.
3. Open it from Applications. The app isn't notarized by Apple, so the first launch is blocked:
   - Go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to ClaudeUsageBar. Confirm.
   - (Or in Terminal: `xattr -dr com.apple.quarantine /Applications/ClaudeUsageBar.app`)
4. When macOS asks whether `security` may read the **Claude Code-credentials** keychain item, click **Always Allow**.

To start it at login, go to System Settings → General → Login Items and add ClaudeUsageBar.

### Requirements

- macOS 13 or later (Apple Silicon or Intel)
- [Claude Code](https://claude.com/claude-code) installed and logged in with your Claude Pro/Max account (run `claude` once). The app reuses that login; it never asks for your password.

## Building from source (optional)

Needs the Xcode Command Line Tools (`xcode-select --install`).

```bash
./scripts/build-app.sh
./scripts/make-dmg.sh
```

New installers are built by GitHub Actions: Actions → Build installer → Run workflow, enter a version.

## How it works

It reads Claude Code's OAuth token from the Keychain (or `~/.claude/.credentials.json`) and calls `https://api.anthropic.com/api/oauth/usage`, the same endpoint behind Claude Code's `/usage` command. That endpoint is undocumented and could change.

If you see "Login expired", run `claude` in Terminal once. Claude Code refreshes the token, and the app picks it up on its next refresh. The app deliberately doesn't refresh the token itself, because that would log Claude Code out.
