# Puzzle Kids cropped PNG staging pipeline

PR1/PR2/PR3 boundary: root PNGs in `assets/images/*.png` are local staging inputs only. They are user-provided, ignored by git, excluded from `pubspec.yaml`, and never used directly at runtime. `assets/images/varios assets.png` is an accidental local source/staging filename and is ignored explicitly; do not delete it, stage it, bundle it, or reference it from the runtime catalog.

Run offline from repo root:

```bash
python assets/source/puzzles/generate_cropped_user_assets.py
```

Policy:

- Reads exactly 9 root PNG inputs: `astro`, `camiones`, `car`, `castillo`, `castillo-princesa`, `dinosaurios`, `doctora`, `princesa`, `animales`.
- No network, downloads, emoji assets, or external source images.
- Center-crops each source to square, resizes full WebP to 1024x1024 and thumbnail to 256x256.
- Writes categorized local WebP full images (`1024x1024`, `<=800 KiB`) and thumbnails (`256x256`, `<=80 KiB`); runtime must use full images for gameplay and thumbnails for selection, never pre-sliced pieces.
- Regenerates `provenance.json` with exact source/full/thumb bytes, sha256, dimensions, format, crop box, mapping gate status, and runtime ID/category.

PR2 owns catalog/runtime mapping. Current approved mappings are recorded in `provenance.json` and mirrored in `assets/catalog/asset_licenses.json`, `assets/catalog/puzzles.json`, and `lib/services/puzzle_catalog_service.dart`. `castillo-princesa` keeps its published WebP unchanged.

Rollback/provenance:

- Preserve `assets/source/puzzles/atlas-replacements.md`; it is the before/after table for base `3d98dcb`, approved replacements/new IDs, unchanged published `castillo-princesa`, and rollback commands.
- After any source/image change, regenerate metadata offline and rerun focused policy/catalog/selection/game tests before review.
