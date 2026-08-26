# Google粵拼forMac

An unofficial, personal macOS Cantonese input source that reproduces the typing workflow of [`tinycrate/gcantonese-ime`](https://github.com/tinycrate/gcantonese-ime). It registers under **Cantonese, Traditional** and retrieves candidates from Google Input Tools.

> [!IMPORTANT]
> This project is not made, endorsed, or supported by Google. The Google Input Tools endpoint used by the original Windows project is undocumented and may change or stop working.

## Current status

- Windows source preparation: implemented.
- Google response contract: covered by fixtures and a live validation script.
- Xcode build: verified by GitHub Actions on Apple Silicon with macOS 15 and Xcode 16.
- macOS InputMethodKit build, signing, installation, and server launch: verified on a local Mac.
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
- An Apple ID added in Xcode Settings → Accounts, with an Apple Development
  certificate available for your Personal Team or paid development team

Authenticate GitHub CLI and clone the private repository:

```zsh
gh auth login --hostname github.com --git-protocol https --web
gh repo clone Fkuzzl/GoogleYuepinForMac
cd GoogleYuepinForMac
```

Run the Mac preflight. It checks the machine and Xcode setup, runs the core tests,
builds the Release app with Xcode automatic signing, rejects an ad-hoc result,
and verifies the input-source metadata. A paid Apple Developer account is not
required for a personal installation; Xcode can use a Personal Team:

```zsh
/bin/zsh Scripts/test-on-mac.sh
```

The script uses the team configured in the Xcode project. If it is not stored
there, it attempts to resolve the only Apple Development team in your login
keychain. When multiple teams exist, select one explicitly:

```zsh
GOOGLE_YUEPIN_DEVELOPMENT_TEAM=YOUR10CHARID /bin/zsh Scripts/test-on-mac.sh
```

The preflight prints the exact built-app path. By default, DerivedData is placed
in macOS's per-user temporary directory rather than inside the repository. This
prevents iCloud Drive and other File Provider services from attaching metadata
that invalidates local code signing. Advanced users can override the location
with `GOOGLE_YUEPIN_DERIVED_DATA`.

## Install for local testing

Installation writes to the system-wide `/Library/Input Methods` directory,
which current macOS versions reliably scan for third-party InputMethodKit apps.
The installer asks for your Mac administrator password to copy the app there.
An Apple Development signature from a free Personal Team is sufficient for the
build and core tests, but it is not accepted by Text Input Source discovery on
all current macOS configurations. In particular, macOS 15.6 rejects the tested
Personal Team build during its policy scan even though `codesign` verifies it.
A Developer ID-signed and notarized build is therefore required for end-to-end
input-source testing on affected Macs. The installer detects the Personal Team
rejection instead of repeatedly suggesting another login. The installed bundle
is owned by `root:wheel`, like other system-wide input methods, so it is not
user-writable code in a privileged directory. Any older user-local copy in
`~/Library/Input Methods` is removed to avoid duplicate input-source IDs:

```zsh
/bin/zsh Scripts/install-local.sh
```

The installer removes generated duplicate app bundles and registers the single
installed copy. macOS may not expose a newly installed or modified input method
until the next login session. Then:

1. Check the macOS input menu for **Google粵拼forMac**.
2. If it is not shown immediately, log out of macOS and log in again. Repeated
   registration attempts cannot replace this session refresh on recent macOS.
3. If needed, open System Settings → Keyboard → Text Input → Edit, click `+`,
   and look under **Cantonese, Traditional**.
4. Switch to it with the normal macOS Input Source shortcut.

Test in TextEdit first: type `nei`, confirm `你` appears, and press Space.

To inspect or build the project in Xcode, run:

```zsh
open GoogleYuepinForMac.xcodeproj
```

## Privacy

Romanized text being composed is sent over HTTPS to Google Input Tools to retrieve candidates. Results are cached locally for 30 days. The project has no analytics and does not intentionally log composed text. See [PRIVACY.md](PRIVACY.md).

## Development notes

The pure Swift engine is a Swift Package so it can be tested separately with `swift test`. The Xcode application target compiles the same core source files together with the InputMethodKit adapter. See [DEVELOPMENT.md](DEVELOPMENT.md).
