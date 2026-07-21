import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/services/asset_manifest_validator.dart';

void main() {
  group('AssetManifestValidator', () {
    test('accepts a local approved asset with complete provenance', () {
      final entry = _entry();

      expect(
        AssetManifestValidator.validateEntries(
          [entry],
          existingAssetPaths: {entry.path},
        ),
        isEmpty,
      );
      expect(
        AssetManifestValidator.approvedUsableAssets(
          [entry],
          existingAssetPaths: {entry.path},
        ),
        [entry],
      );
    });

    test('rejects unapproved assets as invalid manifest entries', () {
      final issues = AssetManifestValidator.validateEntries(
        [_entry(approved: false)],
        existingAssetPaths: {'assets/images/castles/castle-bright.webp'},
      );

      expect(
        issues,
        contains(
          predicate<AssetManifestIssue>(
            (issue) =>
                issue.field == 'approved' &&
                issue.message.contains('must be approved'),
          ),
        ),
      );
      expect(
        AssetManifestValidator.approvedUsableAssets(
          [_entry(approved: false)],
          existingAssetPaths: {'assets/images/castles/castle-bright.webp'},
        ),
        isEmpty,
      );
    });

    test('rejects assets without required license metadata', () {
      final issues = AssetManifestValidator.validateEntries(
        [
          _entry(origin: ''),
          _entry(id: 'missing-license', license: ''),
          _entry(id: 'missing-attribution', attribution: ''),
        ],
        existingAssetPaths: {'assets/images/castles/castle-bright.webp'},
      );

      expect(issues, hasLength(3));
      expect(
        issues.map((issue) => issue.field),
        containsAll(['origin', 'license', 'attribution']),
      );
    });

    test('rejects approved assets without reviewer approval metadata', () {
      final issues = AssetManifestValidator.validateEntries(
        [
          _entry(approvedBy: ''),
          _entry(id: 'missing-approved-at', approvedAt: ''),
          _entry(id: 'bad-approved-at', approvedAt: 'yesterday'),
        ],
        existingAssetPaths: {'assets/images/castles/castle-bright.webp'},
      );

      expect(issues, hasLength(3));
      expect(
        issues.map((issue) => issue.field),
        containsAll(['approvedBy', 'approvedAt']),
      );
    });

    test('rejects assets without byte size metadata', () {
      final issues = AssetManifestValidator.validateEntries(
        [
          AssetManifestEntry.fromJson({
            'id': 'missing-bytes',
            'path': 'assets/images/castles/missing-bytes.webp',
            'origin': 'Example origin',
            'license': 'CC0-1.0',
            'attribution': 'Example attribution',
            'approved': true,
            'approvedBy': 'Legal reviewer',
            'approvedAt': '2026-07-21T00:00:00Z',
            'dimensions': {'width': 1024, 'height': 1024},
            'format': 'webp',
          }),
        ],
        existingAssetPaths: {'assets/images/castles/missing-bytes.webp'},
      );

      expect(
        issues,
        contains(
          predicate<AssetManifestIssue>(
            (issue) =>
                issue.field == 'bytes' && issue.message.contains('required'),
          ),
        ),
      );
    });

    test('rejects hotlinks traversal paths formats and oversized assets', () {
      final issues = AssetManifestValidator.validateEntries([
        _entry(path: 'https://example.com/castle.webp'),
        _entry(id: 'traversal', path: 'assets/images/../castle.webp'),
        _entry(
          id: 'jpg',
          path: 'assets/images/castles/castle.jpg',
          format: 'jpg',
        ),
        _entry(
          id: 'huge-bytes',
          bytes: AssetManifestPolicy.defaultPolicy.maxBytes + 1,
        ),
        _entry(
          id: 'huge-dimensions',
          width: AssetManifestPolicy.defaultPolicy.maxDimension + 1,
        ),
      ], existingAssetPaths: const {});

      expect(
        issues.map((issue) => issue.field),
        containsAll(['path', 'format', 'bytes', 'dimensions']),
      );
    });

    test('excludes approved assets when the local file is missing', () {
      final entry = _entry();

      expect(
        AssetManifestValidator.validateEntries([entry]),
        contains(
          predicate<AssetManifestIssue>(
            (issue) =>
                issue.field == 'path' && issue.message.contains('missing'),
          ),
        ),
      );
      expect(AssetManifestValidator.approvedUsableAssets([entry]), isEmpty);
    });

    test('parses manifest json maps deterministically', () {
      final entry = AssetManifestEntry.fromJson({
        'id': 'castle-bright',
        'path': 'assets/images/castles/castle-bright.webp',
        'origin': 'https://example.org/public-domain-castle',
        'license': 'CC0-1.0',
        'attribution': 'Example Archive, CC0',
        'approved': true,
        'approvedBy': 'Legal reviewer',
        'approvedAt': '2026-07-21T00:00:00Z',
        'dimensions': {'width': 1024, 'height': 1024},
        'format': 'webp',
        'bytes': 320000,
      });

      expect(entry.id, 'castle-bright');
      expect(entry.width, 1024);
      expect(entry.height, 1024);
      expect(entry.approved, isTrue);
      expect(entry.approvedBy, 'Legal reviewer');
      expect(entry.approvedAt, '2026-07-21T00:00:00Z');
    });

    test('keeps bundled sample manifest local unapproved and rejected', () {
      final manifestFile = File('assets/catalog/asset_licenses.json');
      final decoded =
          jsonDecode(manifestFile.readAsStringSync()) as List<Object?>;
      final entries = decoded
          .cast<Map<String, Object?>>()
          .map(AssetManifestEntry.fromJson)
          .toList(growable: false);

      expect(entries, isNotEmpty);
      expect(entries.every((entry) => entry.approved == false), isTrue);
      expect(
        AssetManifestValidator.validateEntries(
          entries,
        ).map((issue) => issue.field),
        contains('approved'),
      );
      expect(AssetManifestValidator.approvedUsableAssets(entries), isEmpty);
    });
  });
}

AssetManifestEntry _entry({
  String id = 'castle-bright',
  String path = 'assets/images/castles/castle-bright.webp',
  String origin = 'https://example.org/public-domain-castle',
  String license = 'CC0-1.0',
  String attribution = 'Example Archive, CC0',
  String approvedBy = 'Legal reviewer',
  String approvedAt = '2026-07-21T00:00:00Z',
  String format = 'webp',
  int width = 1024,
  int height = 1024,
  int bytes = 320000,
  bool approved = true,
}) {
  return AssetManifestEntry(
    id: id,
    path: path,
    origin: origin,
    license: license,
    attribution: attribution,
    approved: approved,
    approvedBy: approvedBy,
    approvedAt: approvedAt,
    width: width,
    height: height,
    format: format,
    bytes: bytes,
  );
}
