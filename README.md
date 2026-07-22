<div align="center">

<img src="assets/icon.png" width="128" alt="Caffeine Widget icon">

# Caffeine Widget ☕

**A tiny macOS menu-bar app to keep your Mac awake — one click.**

No Dock clutter, no windows, no dependencies. Just a little coffee cup in your
menu bar that toggles [`caffeinate`](https://ss64.com/mac/caffeinate.html) on and off.

</div>

---

## Features

- **One-click toggle** — left-click the cup to keep your Mac awake or let it sleep.
  - ☕ Empty cup = sleep allowed
  - ☕ Filled cup = staying awake
- **Timed modes** — "Keep awake for…" 15 min, 30 min, 1, 2, or 4 hours, then it turns off automatically.
- **Launch at Login** — optional, toggled right from the menu.
- **Menu-bar only** — no Dock icon, no window, effectively zero footprint.
- **Native & dependency-free** — ~150 lines of Swift/AppKit. No Homebrew, no Python, nothing to install.

## Menu

Right-click (or Control-click) the cup:

```
☕️  Awake until 3:45 PM        ← live status
──────────────
Let it sleep / Keep awake       ← indefinite toggle
Keep awake for…  ▸  15 min / 30 min / 1 hr / 2 hr / 4 hr
──────────────
✓ Launch at Login
──────────────
Quit Caffeine Widget
```

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools (for building) — `xcode-select --install`

## Build & Install

```bash
git clone https://github.com/owibo4ka/caffeine-widget.git
cd caffeine-widget
./build.sh
```

`build.sh` compiles the app, generates the icon, and installs
**Caffeine Widget.app** into `/Applications`. Then just open it:

```bash
open "/Applications/Caffeine Widget.app"
```

Look for the coffee cup in your menu bar (top-right). On MacBooks with a notch,
you may need to ⌘-drag menu-bar icons to pull it out from behind the notch.

> **First launch blocked?** The app is ad-hoc signed (not from the App Store).
> If macOS blocks it, go to **System Settings → Privacy & Security → Open Anyway**,
> or run `xattr -dr com.apple.quarantine "/Applications/Caffeine Widget.app"`.

## How it works

Toggling "on" launches `caffeinate -dimsu` as a child process:

| flag | meaning |
|------|---------|
| `-d` | prevent the **display** from sleeping |
| `-i` | prevent the system from **idle** sleeping |
| `-m` | prevent the **disk** from idle sleeping |
| `-s` | prevent **system** sleep (even on AC power) |
| `-u` | mark the **user** as active |

Toggling "off" (or quitting the app) terminates that process. Timed modes just
schedule an automatic "off" with a `Timer`.

## Project layout

```
main.swift      # the menu-bar app (AppKit)
makeicon.swift  # renders the app icon at build time
Info.plist      # bundle metadata (LSUIElement = menu-bar-only)
build.sh        # compile + package + install to /Applications
```

## Uninstall

```bash
# Quit it first (right-click cup → Quit), then:
rm -rf "/Applications/Caffeine Widget.app"
```

If you enabled Launch at Login, toggle it off in the menu before removing.

## License

[MIT](LICENSE) — do whatever you like. Enjoy your caffeinated Mac. ☕
