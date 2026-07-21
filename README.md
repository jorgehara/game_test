# puzzle_kids

A new Flutter project.

## Asset governance policy

Puzzle images must be local, offline, and approved before UI can render them as real assets. Do not hotlink, scrape, or add copyrighted binaries without documented permission.

Manifest entries live in `assets/catalog/asset_licenses.json` and must include `id`, `path`, `origin`, `license`, `attribution`, `approved`, `approvedBy`, `approvedAt`, `dimensions`, `format`, and `bytes`. `bytes` is required, not optional. Approved entries must point to an existing local file under `assets/images/` and pass `AssetManifestValidator` policy: PNG/WebP only, no path traversal/external URLs, max 2048px dimension, max 800 KiB per image.

The bundled manifest is a sample policy document only: every entry is `approved: false`, no image binaries are bundled, and those sample entries must be rejected by validation and excluded from rendering. `PkImageTile` must keep the vector/color fallback unless an entry is approved, reviewed, local, and present on disk.

Legal example once a local file exists:

```json
{
  "id": "castle-bright",
  "path": "assets/images/castles/castle-bright.webp",
  "origin": "https://example.org/public-domain-castle",
  "license": "CC0-1.0",
  "attribution": "Example Archive, CC0",
  "approved": true,
  "approvedBy": "Legal reviewer name",
  "approvedAt": "2026-07-21T00:00:00Z",
  "dimensions": { "width": 1024, "height": 1024 },
  "format": "webp",
  "bytes": 320000
}
```

Until approval and local files exist, catalog cards must use `PkImageTile` vector/color fallback.

## Release validation evidence

Run from the project root with the Flutter SDK configured in `android/local.properties` (`C:\src\flutter` locally):

```powershell
& "C:\src\flutter\bin\dart.bat" format --set-exit-if-changed .
& "C:\src\flutter\bin\flutter.bat" analyze
& "C:\src\flutter\bin\flutter.bat" test --reporter compact
& "C:\src\flutter\bin\flutter.bat" test test/widgets/pk_theme_test.dart test/widgets/pk_adaptive_shell_test.dart test/screens/puzzle_selection_screen_test.dart test/screens/puzzle_game_screen_test.dart --reporter compact
& "C:\src\flutter\bin\flutter.bat" build apk --release
& "C:\src\flutter\bin\flutter.bat" build apk --release --split-per-abi
```

Latest local evidence:

| Gate | Result |
|---|---|
| Format | Passed: 59 files, 0 changed. |
| Analyze | Passed: no issues found. |
| Full tests | Passed: 88 tests. |
| Focused UX tests | Passed: theme, adaptive shell, selection, completion/onboarding/reduced-motion coverage. |
| Release universal APK | Built, but above target: `app-release.apk` = 47,058,122 bytes / 44.88 MiB. |
| Release split APKs | Passed target: armeabi-v7a 13.27 MiB, arm64-v8a 15.89 MiB, x86_64 17.22 MiB. |

Package notes:

- Release `android/app/src/main/AndroidManifest.xml` declares no `INTERNET` permission; debug/profile manifests keep Flutter development `INTERNET` only for tooling.
- `pubspec.yaml` declares no bundled image catalog assets yet, so no real image binaries ship in the current release package.
- Runtime image rendering uses `Image.asset` only for approved local paths and falls back locally on missing assets; code search found no `Image.network`, `NetworkImage`, or full-catalog `precacheImage` usage.
- Release APK contents are dominated by Flutter native libraries; universal APK groups measured: `lib` 44.03 MiB, `assets` 0.14 MiB, `classes` 0.82 MiB. Use split-per-ABI artifacts for the current APK-size gate until app-bundle/play delivery is introduced.
- RAM, startup, and 60fps/frame pacing were not measured in this local validation because no representative Android device/emulator profiling run was performed. They remain release-blocking gates before production declaration.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
