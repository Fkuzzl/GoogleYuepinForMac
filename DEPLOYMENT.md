# Deployment status

Status date: 2026-08-28

## Archived status

**This project is archived.** Development stopped on 2026-08-28 because no paid
Apple Developer Program licence was available. The repository is retained as a
technical record; deployment and runtime acceptance are no longer active phases.

## Implementation achievement statement

The **paid Apple Developer deployment workflow implementation was achieved at
the source/configuration level**.

The repository contains the complete intended path for:

- Xcode automatic signing with an Apple Development certificate and paid Team ID;
- automatic provisioning updates during the Release build;
- rejection of an accidental ad-hoc signature;
- preservation and validation of the InputMethodKit sandbox, network, and Mach
  registration entitlements;
- system-wide installation into `/Library/Input Methods` with `root:wheel`
  ownership;
- removal of known duplicate generated bundles before registration;
- LaunchServices registration and TIS registration/enablement attempts; and
- fresh build numbers to avoid stale input-source metadata caches.

The macOS compile and metadata path has passed GitHub Actions. That runner builds
without the private signing certificate, so it does not validate the paid
certificate or the logged-in user's TIS session.

## Explicit deployment non-achievement statement

Paid developer deployment itself was **not achieved**. The required paid Apple
Developer Program licence was unavailable, so the Developer ID/notarized path
was not executed on the target machine.

The paid deployment was **not actually tested on a physical Mac**. A free
Personal Team build was tested on macOS 15.6 and produced the following evidence:

- core tests and the Release build passed;
- Apple Development signing and `codesign` verification passed;
- system-wide installation and secure ownership passed;
- the InputMethodKit server launched; and
- TIS policy discovery rejected the Personal Team build.

There is no recorded evidence that a paid Developer ID/notarized build appears
under Cantonese, Traditional, can be selected, displays candidates, commits
Cantonese text, or persists across login/restart boundaries.

These items remain unverified even though the repository implementation is
complete.

## Historical physical-Mac acceptance procedure

The following procedure is retained for reference. It was partially completed
with a Personal Team build but not with a paid Developer ID/notarized build.

From the cloned repository on the target Mac:

```zsh
git pull --ff-only
/bin/zsh Scripts/test-on-mac.sh
/bin/zsh Scripts/install-local.sh
```

Acceptance requires recorded evidence for all of the following:

1. All Swift core tests pass.
2. The build prints `Xcode Apple Development signing: PASS`.
3. `codesign --verify --deep --strict` accepts the installed app.
4. The installer reports successful registration and enablement.
5. **Google粵拼forMac** appears under Cantonese, Traditional.
6. TextEdit accepts `nei`, shows `你` as a candidate, and commits it with Space.
7. Candidate selection, paging, Backspace, Escape, Return, and punctuation work.
8. Notes, Safari, and VS Code accept composed text.
9. Cached candidates behave as documented when the network is unavailable.
10. The input source remains available after logout/login.

This checklist did not pass before archival. Items 1–3 were demonstrated with a
Personal Team build, then TIS discovery failed before items 4–10. The paid
Developer ID/notarized path was **not actually tested on a physical Mac**.

## Distribution boundary

Apple Development signing would have been used for development and target-Mac testing.
This repository does not currently implement or claim Developer ID Application
signing, notarization, installer packaging, release hosting, or public deployment
to other users. Those are a separate future distribution phase.

No future phase is planned while the project remains archived.
