# Development guide

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

On Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\Scripts\validate.ps1
powershell -ExecutionPolicy Bypass -File .\Scripts\validate.ps1 -LiveEndpoint
```

On macOS:

```zsh
swift test
xcodebuild -project GoogleYuepinForMac.xcodeproj -scheme GoogleYuepinForMac -configuration Release -derivedDataPath .build/xcode build
codesign --verify --deep --strict .build/xcode/Build/Products/Release/GoogleYuepinForMac.app
```

Runtime acceptance must cover TextEdit, Notes, Safari, and VS Code; input-source switching; candidate selection/paging; punctuation; cancellation; and network-disabled fallback.

## Known validation boundary

Windows cannot compile InputMethodKit or run Xcode. A successful Windows validator proves repository structure and external response compatibility, not that the macOS target compiles or registers. Do not mark the macOS phase complete until the Mac commands and runtime checks pass.
