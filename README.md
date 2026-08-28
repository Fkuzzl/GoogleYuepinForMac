# Google粵拼forMac

An unofficial, personal macOS Cantonese input source that reproduces the typing workflow of [`tinycrate/gcantonese-ime`](https://github.com/tinycrate/gcantonese-ime). It registers under **Cantonese, Traditional** and retrieves candidates from Google Input Tools.

> [!CAUTION]
> **Project status: Archived.** Development stopped on 2026-08-28 because the
> project does not have a paid Apple Developer Program licence. A free Personal
> Team build was tested on a Mac and rejected by TIS discovery; paid Developer
> ID deployment and live typing were never tested.

> [!IMPORTANT]
> This project is not made, endorsed, or supported by Google. The Google Input Tools endpoint used by the original Windows project is undocumented and may change or stop working.

## Current status

- Project lifecycle: **archived; no further development is planned**.
- Windows source preparation: implemented.
- Google response contract: covered by fixtures and a live validation script.
- Xcode build: verified by GitHub Actions on Apple Silicon with macOS 15 and Xcode 16.
- Paid Apple Developer deployment workflow implementation: achieved at the
  source/configuration level.
  The project supports Xcode signing, preserves the required entitlements,
  installs one system-wide copy, and attempts registration through the Text
  Input Source APIs.
- Personal Team diagnostic: build, Apple Development signing, system-wide
  installation, and InputMethodKit server launch were tested on macOS 15.6.
  The installed app passed `codesign` verification but was rejected by the TIS
  policy scan.
- Paid developer deployment itself: **not achieved** because no paid Apple
  Developer Program licence was available.
- Paid Developer ID/notarized deployment and live typing: **not actually tested
  on a machine** and therefore not runtime-verified.
- Public distribution: not achieved. The app is not Developer ID signed,
  notarized, packaged, or validated for distribution to other users.

> [!WARNING]
> In this documentation, **workflow implementation achieved** means only that
> the paid Apple Developer signing path exists in the archived source. Paid
> deployment was not performed. The free Personal Team build was machine-tested
> only far enough to diagnose TIS rejection; the input source never appeared for
> selection and live typing was not tested.

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

## Archived build instructions

The following instructions are retained for historical reference. The Personal
Team path was run on a physical Mac; the paid Developer ID path was not.

Requirements:

- Apple Silicon Mac
- macOS 15+
- Xcode 16+
- Command Line Tools selected in Xcode Settings → Locations
- An Apple ID added in Xcode Settings → Accounts, with an Apple Development
  certificate available for a paid development team

Authenticate GitHub CLI and clone the private repository:

```zsh
gh auth login --hostname github.com --git-protocol https --web
gh repo clone Fkuzzl/GoogleYuepinForMac
cd GoogleYuepinForMac
```

Run the Mac preflight. It checks the machine and Xcode setup, runs the core tests,
builds the Release app with Xcode automatic signing, rejects an ad-hoc result,
and verifies the input-source metadata. The Personal Team variant passed this
preflight on the target Mac. The paid Developer ID variant was not run:

```zsh
/bin/zsh Scripts/test-on-mac.sh
```

The script uses the team configured in the Xcode project. If it is not stored
there, it attempts to resolve the only Apple Development team in your login
keychain. When multiple teams exist, set `GOOGLE_YUEPIN_DEVELOPMENT_TEAM` to
the selected team's real 10-character Team ID before running the command.

The preflight prints the exact built-app path. By default, DerivedData is placed
in macOS's per-user temporary directory rather than inside the repository. This
prevents iCloud Drive and other File Provider services from attaching metadata
that invalidates local code signing. Advanced users can override the location
with `GOOGLE_YUEPIN_DERIVED_DATA`.

## Archived installation instructions

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

These steps were the intended acceptance test and are no longer an active
development phase. System-wide installation and server launch succeeded with a
Personal Team build, but TIS discovery failed. No candidate display or committed
Cantonese text was recorded. See [DEPLOYMENT.md](DEPLOYMENT.md) for the exact
tested/unverified boundary and historical acceptance checklist.

To inspect or build the project in Xcode, run:

```zsh
open GoogleYuepinForMac.xcodeproj
```

## Privacy

Romanized text being composed is sent over HTTPS to Google Input Tools to retrieve candidates. Results are cached locally for 30 days. The project has no analytics and does not intentionally log composed text. See [PRIVACY.md](PRIVACY.md).

## Development notes

The pure Swift engine is a Swift Package so it can be tested separately with
`swift test`. The Xcode application target compiles the same core source files
together with the InputMethodKit adapter. See [DEVELOPMENT.md](DEVELOPMENT.md)
and [DEPLOYMENT.md](DEPLOYMENT.md).
