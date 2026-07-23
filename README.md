# 🎭 Script Editor BG — Background Utility

A macOS menu bar utility that lets you insert formatted script text into any app using global keyboard shortcuts. Works in Google Docs, Pages, TextEdit, or any text field.

## Features

- **Global Shortcuts** — Works in any app, even when not focused
  - `Cmd+1, Cmd+2, Cmd+3...` — Insert character dialogue
  - `Cmd+Shift+H` — Insert Scene Heading
  - `Cmd+Shift+A` — Insert Action Line (▲)
  - `Cmd+Shift+P` — Insert Parenthetical
- **Two Formats**:
  - **Stage Play** — Name: Dialogue format, ▲ prefix for action lines
  - **Screenplay** — Centered names, indented dialogue
- **Menu Bar Icon** — Shows 🎭 in your menu bar for quick access
- **Persistent Config** — Characters and format saved to disk

## How It Works

1. App runs in background (no Dock icon)
2. Press global shortcut anywhere
3. App copies formatted text to clipboard
4. App simulates Cmd+V paste
5. Text appears in your active app

## Requirements

- macOS 13.0+
- **Input Monitoring** permission (for global shortcuts)
- **Accessibility** permission (for simulating paste)

## Installation

### Build from source

```bash
cd ScriptEditorBG

# Build and create .app bundle
make app

# Or install directly to /Applications
make install
```

### First Run

1. Double-click `ScriptEditorBG.app`
2. macOS will ask for permissions:
   - **Input Monitoring**: Required to capture global shortcuts
   - **Accessibility**: Required to paste text into other apps
3. Grant both in **System Preferences > Security & Privacy**
4. Relaunch the app

## Usage

### Setting Up Characters

1. Click 🎭 in menu bar
2. Select **Open Settings**
3. Add your characters
4. Choose Stage Play or Screenplay format

### Writing in Any App

1. Open Google Docs, Pages, or any text editor
2. Place cursor where you want text
3. Press shortcuts:
   - `Cmd+1` → "JEREMY: "
   - `Cmd+2` → "ALICE: "
   - `Cmd+Shift+H` → Scene heading
   - `Cmd+Shift+A` → ▲ Action line

### Stage Play Format Example

```
JEREMY: 我唔能夠相信你會咁做。

ALICE: (冷靜地)
你會釋懷嘅。

▲ Jeremy 站起身，望出窗外。
```

## Important Notes

- **Clipboard**: The app temporarily overwrites your clipboard to paste text. Previous clipboard content is restored after 0.1 seconds.
- **Permissions**: If shortcuts don't work, check that both Input Monitoring and Accessibility permissions are granted.
- **Some apps**: May block simulated keystrokes (rare).

## File Structure

```
ScriptEditorBG/
├── Package.swift              # Swift Package Manager manifest
├── Makefile                   # Build automation
├── Info.plist                 # App bundle (LSUIElement = background)
├── README.md                  # This file
└── Sources/
    └── ScriptEditorBG/
        ├── AppDelegate.swift      # Menu bar setup, permissions
        ├── EventTapManager.swift  # Global keyboard capture
        ├── TextInserter.swift     # Clipboard + paste simulation
        ├── ConfigManager.swift    # Settings persistence
        └── SettingsView.swift     # Settings window UI
```

## Troubleshooting

### Shortcuts not working
1. Check 🎭 menu bar icon is visible
2. Open Settings → check permissions status
3. Re-grant permissions in System Preferences
4. Restart the app

### Text not pasting
- Some apps (like Terminal) may not accept simulated pastes
- Try using the menu bar buttons instead

## License

MIT License — free for personal use.
