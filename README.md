# puzzle_kids

A new Flutter project.

## Android launcher icon

The launcher icon is project-owned artwork: `assets/source/icon/puzzle-kids-icon.svg` documents origin as `PROJECT-OWNED`. It uses original vector puzzle-piece geometry, high-contrast child-friendly colors, no embedded text, and no external image assets. Android uses legacy density PNG resources plus adaptive icon foreground/background resources under `android/app/src/main/res/`.

## Asset governance policy

Puzzle images must be local, offline, and approved before UI can render them as real assets. Pinterest may be used only as visual reference/discovery; do not hotlink, scrape, or add Pinterest/external/copyrighted binaries without documented permission from the original source.

Manifest entries live in `assets/catalog/asset_licenses.json` and must include exactly these fields: `id`, `path`, `thumbnailPath`, `sourceTitle`, `sourceUrl`, `license`, `licenseUrl`, `attribution`, `approved`, `approvedBy`, `approvedAt`, `dimensions`, `format`, `bytes`, and `sha256`. `dimensions` is a nested object with `width` and `height`; the manifest does not use top-level `width` or `height` fields. `origin` is not a manifest field. Approved entries must point to an existing local file under `assets/images/` and pass `AssetManifestValidator` policy: PNG/WebP only, no path traversal/external URLs, max 2048px dimension, max 800 KiB per full image, and 256x256 thumbnails when `thumbnailPath` is present.

The bundled starter pack is PROJECT-OWNED artwork generated locally from editable SVG sources under `assets/source/puzzles/` by `assets/source/puzzles/generate_project_owned_pack.py`. The generator uses local Python/SVG source owned by this project and is reproducible without network, downloads, Pinterest images, or external rasterizers. Every approved entry uses `license: "PROJECT-OWNED"`, `sourceUrl: "project-owned://..."`, explicit Puzzle Kids attribution, measured local PNG metadata, and SHA-256 hashes.

Legal example once a local file exists:

```json
{
  "id": "castle-bright",
  "path": "assets/images/castles/castle-bright.png",
  "thumbnailPath": "assets/images/castles/castle-bright_thumb.png",
  "sourceTitle": "Puzzle Kids original vector illustration - Castillo brillante",
  "sourceUrl": "project-owned://assets/source/puzzles/castle-bright.svg",
  "license": "PROJECT-OWNED",
  "licenseUrl": "project-owned://LICENSE",
  "attribution": "Puzzle Kids PROJECT-OWNED original local vector artwork.",
  "approved": true,
  "approvedBy": "Puzzle Kids project owner",
  "approvedAt": "2026-07-22T00:00:00Z",
  "dimensions": {
    "width": 512,
    "height": 512
  },
  "format": "png",
  "bytes": 4097,
  "sha256": "48b56661b5f06706927067db4f4b9cdf3280d8ed89e8be22aec82b25349f6e79"
}
```

Catalog entries without approved local files must keep using the `PkImageTile` vector/color fallback. Runtime loading is local/offline only: `PuzzleSelectionScreen` loads approved entries from the bundled `assets/catalog/asset_licenses.json`, derives approved bundled paths, renders `thumbnailPath` in selection when present, and falls back locally on missing, corrupt, unapproved, or loader-error cases. Puzzle art must not use `Image.network`, hotlinks, or external image requests.

## Project-owned starter puzzle pack

Slice 3 ships 9 offline PNG puzzle illustrations plus 9 thumbnails, all generated without Pinterest, downloads, scraping, or external rasterizers:

| Theme | Source | Full | Thumbnail |
|---|---|---|---|
| castle-bright | `assets/source/puzzles/castle-bright.svg` | `assets/images/castles/castle-bright.png` | `assets/images/castles/castle-bright_thumb.png` |
| princess-crown | `assets/source/puzzles/princess-crown.svg` | `assets/images/princesses/princess-crown.png` | `assets/images/princesses/princess-crown_thumb.png` |
| unicorn-cloud | `assets/source/puzzles/unicorn-cloud.svg` | `assets/images/unicorns/unicorn-cloud.png` | `assets/images/unicorns/unicorn-cloud_thumb.png` |
| dragon-kite | `assets/source/puzzles/dragon-kite.svg` | `assets/images/dinosaurs/dragon-kite.png` | `assets/images/dinosaurs/dragon-kite_thumb.png` |
| mermaid-lagoon | `assets/source/puzzles/mermaid-lagoon.svg` | `assets/images/ocean/mermaid-lagoon.png` | `assets/images/ocean/mermaid-lagoon_thumb.png` |
| rocket-moon | `assets/source/puzzles/rocket-moon.svg` | `assets/images/space/rocket-moon.png` | `assets/images/space/rocket-moon_thumb.png` |
| fox-forest | `assets/source/puzzles/fox-forest.svg` | `assets/images/animals/fox-forest.png` | `assets/images/animals/fox-forest_thumb.png` |
| rainbow-bus | `assets/source/puzzles/rainbow-bus.svg` | `assets/images/vehicles/rainbow-bus.png` | `assets/images/vehicles/rainbow-bus_thumb.png` |
| berry-cupcake | `assets/source/puzzles/berry-cupcake.svg` | `assets/images/fruits/berry-cupcake.png` | `assets/images/fruits/berry-cupcake_thumb.png` |

Regenerate locally with:

```powershell
python assets\source\puzzles\generate_project_owned_pack.py
```

The generator updates `assets/catalog/asset_licenses.json` with byte counts and SHA-256 hashes from actual files.

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
| Format | Passed: 62 files, 0 changed. |
| Analyze | Passed: no issues found. |
| Full tests | Passed: 107 tests. |
| Focused asset runtime tests | Passed: loader + selection focused suite, 7 tests. |
| Focused UX tests | Passed previously: theme, adaptive shell, selection, completion/onboarding/reduced-motion coverage. |
| Release universal APK | Built, but above target: `app-release.apk` = 47,058,122 bytes / 44.88 MiB. |
| Release split APKs | Passed target: armeabi-v7a 13.27 MiB, arm64-v8a 15.89 MiB, x86_64 17.22 MiB. |

Package notes:

- Release `android/app/src/main/AndroidManifest.xml` declares no `INTERNET` permission; debug/profile manifests keep Flutter development `INTERNET` only for tooling.
- `pubspec.yaml` declares `assets/catalog/` and `assets/images/`; the current project-owned starter image pack is intentionally small and locally validated.
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
