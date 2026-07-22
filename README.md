# puzzle_kids

A new Flutter project.

## Android launcher icon

The launcher icon is project-owned artwork: `assets/source/icon/puzzle-kids-icon.svg` documents origin as `PROJECT-OWNED`. It uses original vector puzzle-piece geometry, high-contrast child-friendly colors, no embedded text, and no external image assets. Android uses legacy density PNG resources plus adaptive icon foreground/background resources under `android/app/src/main/res/`.

## Asset governance policy

Puzzle images must be local, offline, and approved before UI can render them as real assets. Pinterest may be used only as visual reference/discovery; do not hotlink, scrape, or add Pinterest/external/copyrighted binaries without documented permission from the original source.

Manifest entries live in `assets/catalog/asset_licenses.json` and must include exactly these fields: `id`, `path`, `thumbnailPath`, `sourceTitle`, `sourceUrl`, `license`, `licenseUrl`, `attribution`, `approved`, `approvedBy`, `approvedAt`, `dimensions`, `format`, `bytes`, and `sha256`. `dimensions` is a nested object with `width` and `height`; the manifest does not use top-level `width` or `height` fields. `origin` is not a manifest field. Approved entries must point to an existing local file under `assets/images/` and pass `AssetManifestValidator` policy: PNG/WebP only, no path traversal/external URLs, max 2048px dimension, max 800 KiB per full image, and 256x256 thumbnails when `thumbnailPath` is present.

The bundled starter pack is PROJECT-OWNED artwork generated locally from editable SVG sources under `assets/source/puzzles/` by `assets/source/puzzles/generate_project_owned_pack.py`, plus the user-provided original `assets/images/castillo-princesa.png` optimized offline into WebP. The atlas/cropped pack is derived from local project-owned/user-provided sources only: preserved atlas entries came from `assets/images/varios-assets.png`; PR2 replacements/new IDs came from the nine staging PNGs recorded in `assets/source/puzzles/provenance.json`. The accidental local file `assets/images/varios assets.png` is ignored as staging/source-only and must not be bundled, cataloged, or committed. The generator, optimization workflow, and offline atlas extraction pipeline use local project/user-owned source only and are reproducible without network, downloads, Pinterest images, emojis, pre-sliced pieces, or external rasterizers. Every approved entry uses `license: "PROJECT-OWNED"`, `sourceUrl: "project-owned://..."`, explicit Puzzle Kids attribution, measured local PNG/WebP metadata, and SHA-256 hashes.

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

Slice 3 ships 9 offline PNG puzzle illustrations plus 9 PNG thumbnails, all generated without Pinterest, downloads, scraping, or external rasterizers. Slice 1 of `puzzle-image-piece-rendering` adds 1 user-provided PROJECT-OWNED WebP puzzle plus WebP thumbnail, optimized offline from `assets/images/castillo-princesa.png`. Slice 3 of `puzzle-kids-atlas-assets` adds 9 atlas-derived full WebP puzzle images plus 9 WebP thumbnails extracted offline from explicit crop boxes in `assets/source/puzzles/atlas_crop_metadata.json`. Legal ownership: every entry is `PROJECT-OWNED`, sourced from editable local SVG under `assets/source/puzzles/`, user-owned local originals, or the approved user-owned atlas, approved by `Puzzle Kids project owner`, and attributed as Puzzle Kids original/local artwork.

Pack measurement from the current manifest and files: 21 full images, 21 thumbnails at 256x256, PNG/WebP format, 1,500,020 bytes total image binaries. The atlas subset contains exactly 11 full WebP images totaling 1,013,262 bytes and 11 WebP thumbnails totaling 201,966 bytes; max atlas full image is 118,024 bytes and max atlas thumbnail is 22,794 bytes. The optimized `castillo-princesa` full asset is 1024x1024, 131,770 bytes, SHA-256 `92b69c509f6baac96d9348dea093259dcb4d058eefad6186e1db97277c9929fc`; its thumbnail is 256x256, 14,322 bytes, SHA-256 `8e446f9f0b86fd8a784ba8ef440b67deb53c6f6f64c4a1e7db611ad646cfd872`. Full max is 131,770 bytes; thumbnail max is 22,794 bytes; all are below the full <=800 KiB, thumbnail <=80 KiB, and pack <4 MiB gates. Original atlas is not bundled, not declared in `pubspec.yaml`, and not listed as a catalog puzzle path.

| Theme | Source | Full PNG 512x512 | Thumbnail PNG 256x256 |
|---|---|---|---|
| castle-bright | `assets/source/puzzles/castle-bright.svg` | `assets/images/castles/castle-bright.png` | `assets/images/castles/castle-bright_thumb.png` |
| castillo-princesa | `assets/images/castillo-princesa.png` | `assets/images/castles/castillo-princesa.webp` (1024x1024 WebP) | `assets/images/castles/castillo-princesa_thumb.webp` |
| princess-crown | `assets/source/puzzles/princess-crown.svg` | `assets/images/princesses/princess-crown.png` | `assets/images/princesses/princess-crown_thumb.png` |
| unicorn-cloud | `assets/source/puzzles/unicorn-cloud.svg` | `assets/images/unicorns/unicorn-cloud.png` | `assets/images/unicorns/unicorn-cloud_thumb.png` |
| dragon-kite | `assets/source/puzzles/dragon-kite.svg` | `assets/images/dinosaurs/dragon-kite.png` | `assets/images/dinosaurs/dragon-kite_thumb.png` |
| mermaid-lagoon | `assets/source/puzzles/mermaid-lagoon.svg` | `assets/images/ocean/mermaid-lagoon.png` | `assets/images/ocean/mermaid-lagoon_thumb.png` |
| rocket-moon | `assets/source/puzzles/rocket-moon.svg` | `assets/images/space/rocket-moon.png` | `assets/images/space/rocket-moon_thumb.png` |
| fox-forest | `assets/source/puzzles/fox-forest.svg` | `assets/images/animals/fox-forest.png` | `assets/images/animals/fox-forest_thumb.png` |
| rainbow-bus | `assets/source/puzzles/rainbow-bus.svg` | `assets/images/vehicles/rainbow-bus.png` | `assets/images/vehicles/rainbow-bus_thumb.png` |
| berry-cupcake | `assets/source/puzzles/berry-cupcake.svg` | `assets/images/fruits/berry-cupcake.png` | `assets/images/fruits/berry-cupcake_thumb.png` |
| atlas-dinosaurs | `project-owned://assets/images/varios-assets.png` crop `[46,0,420,374]` | `assets/images/dinosaurs/atlas-dinosaurs.webp` (1024x1024 WebP) | `assets/images/dinosaurs/atlas-dinosaurs_thumb.webp` |
| atlas-race-car | `project-owned://assets/images/varios-assets.png` crop `[513,0,887,374]` | `assets/images/vehicles/atlas-race-car.webp` (1024x1024 WebP) | `assets/images/vehicles/atlas-race-car_thumb.webp` |
| atlas-princess-castle | `project-owned://assets/images/varios-assets.png` crop `[981,0,1355,374]` | `assets/images/castles/atlas-princess-castle.webp` (1024x1024 WebP) | `assets/images/castles/atlas-princess-castle_thumb.webp` |
| atlas-doctor | `project-owned://assets/images/varios-assets.png` crop `[46,374,420,748]` | `assets/images/professions/atlas-doctor.webp` (1024x1024 WebP) | `assets/images/professions/atlas-doctor_thumb.webp` |
| atlas-astronaut | `project-owned://assets/images/varios-assets.png` crop `[513,374,887,748]` | `assets/images/space/atlas-astronaut.webp` (1024x1024 WebP) | `assets/images/space/atlas-astronaut_thumb.webp` |
| atlas-animals | `project-owned://assets/images/varios-assets.png` crop `[981,374,1355,748]` | `assets/images/animals/atlas-animals.webp` (1024x1024 WebP) | `assets/images/animals/atlas-animals_thumb.webp` |
| atlas-airplane | `project-owned://assets/images/varios-assets.png` crop `[46,748,420,1122]` | `assets/images/vehicles/atlas-airplane.webp` (1024x1024 WebP) | `assets/images/vehicles/atlas-airplane_thumb.webp` |
| atlas-truck | `project-owned://assets/images/varios-assets.png` crop `[513,748,887,1122]` | `assets/images/vehicles/atlas-truck.webp` (1024x1024 WebP) | `assets/images/vehicles/atlas-truck_thumb.webp` |
| atlas-emergency-vehicles | `project-owned://assets/images/varios-assets.png` crop `[981,748,1355,1122]` | `assets/images/vehicles/atlas-emergency-vehicles.webp` (1024x1024 WebP) | `assets/images/vehicles/atlas-emergency-vehicles_thumb.webp` |

Regenerate locally with:

```powershell
python assets\source\puzzles\generate_project_owned_pack.py
```

The generator updates generated SVG-derived entries in `assets/catalog/asset_licenses.json` with byte counts and SHA-256 hashes from actual files. User-provided optimized art entries must keep their measured WebP bytes, dimensions, and SHA-256 in the manifest.

Regenerate atlas derivatives locally only after confirming the source atlas is present and approved:

```powershell
python assets\source\puzzles\extract_atlas_assets.py
```

`assets/source/puzzles/atlas_crop_metadata.json` is the audit ledger for the atlas source SHA-256, 1402x1122 source dimensions, panel boxes, crop boxes, generated bytes, dimensions, and hashes. Keep `assets/images/varios-assets.png` as a local staging input only; the guard is that it must never be staged, bundled in `pubspec.yaml`, or referenced as a generated asset path. Original atlas is not bundled.

Regenerate the cropped user-provided PR2 replacements only from the nine approved root PNG staging inputs:

```powershell
python assets\source\puzzles\generate_cropped_user_assets.py
```

`assets/source/puzzles/provenance.json` maps each approved source to its runtime ID/category, source hash/bytes/dimensions, full WebP metadata, and thumbnail WebP metadata. It must remain in sync with `assets/catalog/asset_licenses.json`, `assets/catalog/puzzles.json`, `lib/services/puzzle_catalog_service.dart`, and the explicit category directories in `pubspec.yaml`. Rollback/traceability lives in `assets/source/puzzles/atlas-replacements.md`; preserve its before/after table when updating image bytes. `castillo-princesa` is intentionally preserved with unchanged published WebP bytes/hash.

Final PR3 review checklist:

- No root PNG staging inputs are staged or declared in `pubspec.yaml` (`assets/images/` broad root inclusion is forbidden).
- No network image loading, hotlinks, emoji assets, downloads, or pre-sliced piece assets are introduced.
- Manifest/catalog/Dart/pubspec/local files agree on every mapped ID, path, category, dimensions, bytes, and SHA-256.
- Only approved replacements/new IDs from `assets/source/puzzles/atlas-replacements.md` changed; unrelated atlas entries remain unchanged.

## Release validation evidence

Run from the project root with the Flutter SDK configured in `android/local.properties` (`C:\src\flutter` locally):

Current no-build gates:

```powershell
& "C:\src\flutter\bin\dart.bat" format --set-exit-if-changed .
& "C:\src\flutter\bin\flutter.bat" analyze
& "C:\src\flutter\bin\flutter.bat" test test/asset_package_policy_test.dart test/services/asset_manifest_validator_test.dart test/services/puzzle_asset_manifest_loader_test.dart test/screens/puzzle_selection_screen_test.dart --reporter compact
& "C:\src\flutter\bin\flutter.bat" test --reporter compact
git diff --check
```

Future release build gates, to run only when release validation is requested:

```powershell
& "C:\src\flutter\bin\flutter.bat" build apk --release
& "C:\src\flutter\bin\flutter.bat" build apk --release --split-per-abi
& "C:\src\flutter\bin\flutter.bat" install --release
```

Latest local evidence:

| Gate | Result |
|---|---|
| Format | Passed: 72 files, 0 changed. |
| Analyze | Passed: no issues found. |
| Full tests | Passed: 109 tests. |
| Focused asset/offline runtime tests | Passed: package policy + validator + loader + catalog + selection + game focused suite, 71 tests. |
| Focused UX tests | Passed previously: theme, adaptive shell, selection, completion/onboarding/reduced-motion coverage. |
| Asset pack size | Passed: 1,500,020 bytes, 8 full PNGs + 8 PNG thumbnails + 1 optimized WebP + 1 WebP thumbnail + 12 generated WebP full images + 12 generated WebP thumbnails. |
| Release universal APK | Stale/pre-current-pack evidence only: `app-release.apk` = 47,058,122 bytes / 44.88 MiB. Do not claim this APK includes the current starter pack until rebuilt. |
| Release split APKs | Stale/pre-current-pack evidence only: armeabi-v7a 13.27 MiB, arm64-v8a 15.89 MiB, x86_64 17.22 MiB. Do not claim these split APKs include the current starter pack until rebuilt. |

Package notes:

- Release `android/app/src/main/AndroidManifest.xml` declares no `INTERNET` permission; debug/profile manifests keep Flutter development `INTERNET` only for tooling.
- `pubspec.yaml` declares `assets/catalog/` plus explicit category directories under `assets/images/<category>/`; broad `assets/images/` root inclusion is forbidden so local staging PNGs cannot be bundled.
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
