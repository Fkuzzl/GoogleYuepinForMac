# Development guide

> [!CAUTION]
> **Archived on 2026-08-28.** Development stopped because no paid Apple
> Developer Program licence was available. This file is retained as a technical
> record, not an active development plan.

## Architecture

The project is intentionally split into two layers:

- `Sources/GoogleYuepinCore`: platform-neutral composition state, Google response parsing/networking, and the SQLite candidate cache.
- `GoogleYuepinForMac`: InputMethodKit lifecycle, macOS key events, marked text, candidate UI, punctuation, and input-source registration.

`CandidateProviding` is the boundary around the undocumented Google service. A future offline provider can implement the same interface without replacing the native input-source layer.

## Input-source identity

- Bundle ID: `local.googleyuepinformac.inputmethod`
- Input-mode ID: `local.googleyuepinformac.inputmethod.GoogleYuepinIM`
- Intended language: `yue-Hant`
- Repertoire: `Hant`
- Connection name: `$(PRODUCT_BUNDLE_IDENTIFIER)_Connection`

The `Info.plist` structure follows the macOS InputMethodKit/Text Input Source pattern. TypeDuck-Mac was inspected only as a compatibility reference; no TypeDuck source code, dictionary data, artwork, or branding is included.

## Candidate flow

1. The controller appends ASCII letters to `CompositionEngine`.
2. Existing requests are cancelled and the current query is sent to `CachedCandidateService`.
3. A fresh cache hit is returned immediately; otherwise `GoogleCandidateProvider` uses the `yue-hant-t-i0-und` input tool.
4. Responses are ignored if the composition query changed before completion.
5. `matched_length` determines how much romanized input a selected candidate consumes.
6. If the network is unavailable, stale cached results are allowed; without a cache hit, raw input remains committable.

## Validation

### Achieved in the repository

- Pure Swift core tests and response fixtures.
- macOS CI compilation and built input-source metadata checks.
- Paid Apple Developer deployment implementation using Xcode automatic Apple
  Development signing and automatic provisioning.
- System-wide installation, duplicate-bundle cleanup, secure `root:wheel`
  ownership, LaunchServices registration, TIS enablement attempts, and
  signature/metadata preflight scripts.

The paid developer deployment workflow is implementation-complete in source.
Paid deployment itself was not achieved because the project had no paid Apple
Developer Program licence. A free Personal Team build was tested on macOS 15.6:
build, signing, system-wide installation, and server launch succeeded, but the
TIS policy scan rejected it before input-source discovery.

On Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\Scripts\validate.ps1
powershell -ExecutionPolicy Bypass -File .\Scripts\validate.ps1 -LiveEndpoint
```

On macOS:

```zsh
/bin/zsh Scripts/test-on-mac.sh
```

Runtime acceptance was intended to cover TextEdit, Notes, Safari, and VS Code;
input-source switching; candidate selection/paging; punctuation; cancellation;
and network-disabled fallback. These typing checks were not performed because
the Personal Team build did not pass TIS discovery.

## Known validation boundary

Windows cannot compile InputMethodKit or run Xcode. GitHub Actions proves that
the target compiles and its generated metadata is structurally correct, but CI
does not have the paid developer certificate or access to a logged-in macOS TIS
session. Therefore:

- Paid Apple Developer deployment implementation: achieved.
- Personal Team build/sign/install/server launch: tested on a physical Mac.
- Personal Team TIS discovery: tested and rejected on macOS 15.6.
- Paid Developer ID/notarized deployment: not actually tested on a machine.
- Candidate UI and live Cantonese typing: not tested because discovery failed.
- Developer ID signing, notarization, packaging, and public distribution: not
  implemented or claimed.

Runtime acceptance remained incomplete when the project was archived. The
historical checklist is retained in [`DEPLOYMENT.md`](DEPLOYMENT.md).
