# Google粵拼forMac

An unofficial, personal macOS Cantonese input source that reproduces the typing workflow of [`tinycrate/gcantonese-ime`](https://github.com/tinycrate/gcantonese-ime). It registers under **Cantonese, Traditional** and retrieves candidates from Google Input Tools.

> [!IMPORTANT]
> This project is not made, endorsed, or supported by Google. The Google Input Tools endpoint used by the original Windows project is undocumented and may change or stop working.

## Current status

- Windows source preparation: implemented.
- Google response contract: covered by fixtures and a live validation script.
- Xcode build: verified by GitHub Actions on Apple Silicon with macOS 15 and Xcode 16.
- macOS InputMethodKit installation and live typing: still needs verification on a local Mac.
- Distribution: personal/local build only; not notarized.

## Behaviour

- Type Cantonese using the same loose romanized input accepted by Google Input Tools.
- Six candidates per page.
- `1`–`6`: choose a candidate.
- Left/Right: change the highlighted candidate.
- Up/Down: change page.
- Space: accept the highlighted candidate.
- Backspace: edit or reopen the previous converted segment.
- Escape: cancel composition.
- Return: commit the current text.
- macOS input-source switching handles English/Cantonese; Shift is not intercepted.

## Build on the Mac

Requirements:

- Apple Silicon Mac
- macOS 15+
- Xcode 16+
- Command Line Tools selected in Xcode Settings → Locations

Authenticate GitHub CLI and clone the private repository:

```zsh
gh auth login --hostname github.com --git-protocol https --web
gh repo clone Fkuzzl/GoogleYuepinForMac
cd GoogleYuepinForMac
```

Run the Mac preflight. It checks the machine and Xcode setup, runs the core tests,
builds the signed Release app, and verifies the input-source metadata:

```zsh
/bin/zsh Scripts/test-on-mac.sh
```

The built input source will be at:

```text
.build/xcode/Build/Products/Release/GoogleYuepinForMac.app
```

## Install for local testing

Installation writes to `/Library/Input Methods` and therefore asks for your Mac administrator password in Terminal:

```zsh
/bin/zsh Scripts/install-local.sh
```

Then:

1. Log out of macOS and log in again.
2. Open System Settings → Keyboard → Text Input → Edit.
3. Click `+`.
4. Select **Cantonese, Traditional**.
5. Add **Google粵拼forMac**.
6. Switch to it with the normal macOS Input Source shortcut.

Test in TextEdit first: type `nei`, confirm `你` appears, and press Space.

To inspect or build the project in Xcode, run:

```zsh
open GoogleYuepinForMac.xcodeproj
```

## Privacy

Romanized text being composed is sent over HTTPS to Google Input Tools to retrieve candidates. Results are cached locally for 30 days. The project has no analytics and does not intentionally log composed text. See [PRIVACY.md](PRIVACY.md).

## Development notes

The pure Swift engine is a Swift Package so it can be tested separately with `swift test`. The Xcode application target compiles the same core source files together with the InputMethodKit adapter. See [DEVELOPMENT.md](DEVELOPMENT.md).
