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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
