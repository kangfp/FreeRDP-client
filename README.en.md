# FreeRDP Client for macOS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

English | [中文](README.md)

A native macOS GUI (SwiftUI) for the command-line [FreeRDP](https://www.freerdp.com).
All common RDP options become graphical controls; connection profiles are saved,
searchable and duplicable; passwords live in the macOS Keychain; sessions come
with live logs.

> **Unofficial project.** This is an independent graphical frontend that invokes
> the FreeRDP binary installed on your machine. It is not affiliated with the
> FreeRDP project. This repository contains no FreeRDP source code or binaries;
> FreeRDP itself is licensed under Apache-2.0.

## Features

- **Profile management** — save / duplicate / delete / search connections
- **Six settings tabs** covering common FreeRDP options:
  - **Connection**: host/port/username/password/domain, window title, admin session, RD Gateway, auto-reconnect
  - **Display**: fullscreen / fixed resolution / screen percentage, dynamic resolution, multimon, span, color depth, HiDPI scaling, smart sizing, floatbar
  - **Performance**: network type, graphics pipeline (auto / Progressive / H.264 AVC420 / AVC444 / RemoteFX / off), compression, JPEG, wallpaper / font smoothing / themes / animations
  - **Local resources**: clipboard (direction & file clipboard), folder redirection (graphical picker), home drive / all mounts, sound (3 modes), microphone, printer, smartcard, USB, keyboard layout / Unicode / grab, timezone
  - **Security**: protocol negotiation (auto / NLA / TLS / RDP / Ext / AAD), certificate policy (TOFU / ignore / deny), TLS seclevel & version enforcement for legacy servers, restricted admin
  - **Advanced**: client binary selection, log level, timeout, prevent session lock, multitransport, extra arguments
- **Command preview** — see the exact FreeRDP command (password masked), copyable
- **Session management** — live log, disconnect, exit codes
- **Lifecycle follow-through** — closing the main window quits the app and
  disconnects all sessions; a watchdog wrapper terminates FreeRDP within ~1s
  even if the app crashes or is force-killed. No orphan connections.

## Security design

- Passwords are stored in the **macOS Keychain**, never in config files (config file mode 0600)
- Arguments are passed via `/args-from:stdin` — **passwords never appear in the `ps` process list**
- Certificate policy defaults to **TOFU** (trust on first use): works out of the box with self-signed servers (e.g. GNOME Remote Desktop), rejects changed certificates

## Requirements

- macOS 14+
- FreeRDP 3: `brew install freerdp` (uses `sdl-freerdp`, native SDL3, no XQuartz needed)
- Building from source requires Xcode or Command Line Tools (Swift 6+)

## Install

1. `brew install freerdp`
2. Download `FreeRDPClient-<version>.dmg` from [Releases](../../releases), open it and drag the app into Applications.

> **First launch:** the DMG is ad-hoc signed (no paid Apple notarization).
> Gatekeeper may block the first launch — right-click the app → **Open** → confirm,
> or run:
> ```bash
> xattr -dr com.apple.quarantine /Applications/FreeRDPClient.app
> ```

## Build from source

```bash
./build.sh            # build → build/FreeRDPClient.app
./build.sh install    # build + install to /Applications
./build.sh dmg        # build + drag-to-install DMG
swift test            # unit tests + real-process integration tests
```

## Tips

- **Windows targets**: defaults just work (auto negotiation + NLA). For legacy systems (Win7), lower TLS seclevel to 0 and enforce TLS 1.0 in the Security tab.
- **Ubuntu GNOME Remote Desktop**: keep protocol auto + cert TOFU; use the credentials configured in GRD.
- **CJK input**: keep "Unicode input" enabled; leave keyboard layout empty for auto-detection.
- **Fullscreen toggle in session**: `Ctrl+Alt+Enter`.
- **File transfer**: add a folder redirection in Local Resources (appears as a network drive in the remote "This PC"), or enable file clipboard.

## License

[MIT](LICENSE) © kang-kmac

This repository contains only the original GUI frontend code. FreeRDP is a
separate Apache-2.0 project installed by the user via Homebrew. UI glyphs use
Apple SF Symbols under their license terms (apps running on Apple platforms).
