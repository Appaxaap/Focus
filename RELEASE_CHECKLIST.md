# Production Release Checklist (Linux)

## 1) Quality Gate

Run locally:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build linux --release
```

All commands must pass with no analyzer errors.

## 2) Security Gate

Run dependency checks:

```bash
flutter pub outdated
flutter pub deps
```

Resolve critical/high-risk dependency issues before release.

## 3) Packaging + Integrity

Generate artifact checksum:

```bash
sha256sum build/linux/x64/release/bundle/focus > build/linux/x64/release/bundle/focus.sha256
```

Publish the checksum next to the release artifact.

## 4) Runtime Validation (Linux)

Manual smoke checks:

- App launches cleanly from fresh boot.
- Single-instance guard works (second launch is blocked with clear message).
- Add/edit/delete/complete tasks.
- Notifications (if enabled) behave as expected.
- Tray/menu actions work or degrade gracefully.

## 5) Known Limitations

- Pairing/sync feature is currently unstable. Keep it marked experimental and do not promote it in release notes.

## 6) Rollback Readiness

- Keep previous stable release attached on GitHub.
- If severe regressions are reported, pin distribution links to prior stable tag immediately.
