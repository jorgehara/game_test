import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/services/asset_manifest_validator.dart';

void main() {
  group('AssetManifestValidator manifest policy', () {
    test('accepts a local approved asset with complete legal metadata', () {
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

    test(
      'rejects missing approval reviewer/date and non-whitelisted licenses',
      () {
        final issues = AssetManifestValidator.validateEntries(
          [
            _entry(approved: false),
            _entry(id: 'missing-reviewer', approvedBy: ''),
            _entry(id: 'bad-approved-at', approvedAt: 'yesterday'),
            _entry(id: 'bad-license', license: 'UNAPPROVED-SAMPLE'),
          ],
          existingAssetPaths: {'assets/images/castles/castle-bright.webp'},
        );

        expect(
          issues.map((issue) => issue.field),
          containsAll(['approved', 'approvedBy', 'approvedAt', 'license']),
        );
        expect(
          AssetManifestValidator.approvedUsableAssets(
            [_entry(approved: false)],
            existingAssetPaths: {'assets/images/castles/castle-bright.webp'},
          ),
          isEmpty,
        );
      },
    );

    test('requires source URL/title license URL and CC BY attribution', () {
      final issues = AssetManifestValidator.validateEntries(
        [
          _entry(sourceTitle: ''),
          _entry(id: 'missing-source-url', sourceUrl: ''),
          _entry(
            id: 'pinterest-source',
            sourceUrl: 'https://pinterest.com/pin/1',
          ),
          _entry(id: 'missing-license-url', licenseUrl: ''),
          _entry(
            id: 'missing-attribution',
            license: 'CC-BY-4.0',
            attribution: '',
          ),
        ],
        existingAssetPaths: {'assets/images/castles/castle-bright.webp'},
      );

      expect(
        issues.map((issue) => issue.field),
        containsAll(['sourceTitle', 'sourceUrl', 'licenseUrl', 'attribution']),
      );
    });

    test(
      'rejects unsafe paths invalid formats oversize dimensions and hashes',
      () {
        final issues = AssetManifestValidator.validateEntries([
          _entry(path: 'https://example.com/castle.webp'),
          _entry(id: 'traversal', path: 'assets/images/../castle.webp'),
          _entry(id: 'windows', path: r'assets\images\castle.webp'),
          _entry(id: 'drive', path: r'C:\tmp\castle.webp'),
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
          _entry(id: 'missing-hash', sha256: ''),
        ]);

        expect(
          issues.map((issue) => issue.field),
          containsAll(['path', 'format', 'bytes', 'dimensions', 'sha256']),
        );
      },
    );

    test('sorts manifest entries by id deterministically', () {
      final sorted = AssetManifestValidator.sortedById([
        _entry(id: 'unicorn-cloud'),
        _entry(id: 'castle-bright'),
        _entry(id: 'princess-crown'),
      ]);

      expect(sorted.map((entry) => entry.id), [
        'castle-bright',
        'princess-crown',
        'unicorn-cloud',
      ]);
    });
  });

  group('AssetManifestValidator filesystem probe boundary', () {
    test(
      'validates real file bytes dimensions format and hash via injected probe',
      () async {
        final entry = _entry(
          thumbnailPath: 'assets/images/castles/castle-bright_thumb.webp',
        );
        final issues = await AssetManifestValidator.validateEntriesWithProbe(
          [entry],
          _FakeProbe({
            entry.path: AssetProbeResult(
              exists: true,
              bytes: entry.bytes,
              width: entry.width,
              height: entry.height,
              format: entry.format,
              sha256: entry.sha256,
            ),
            entry.thumbnailPath!: const AssetProbeResult(
              exists: true,
              bytes: 24000,
              width: 256,
              height: 256,
              format: 'webp',
              sha256:
                  'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            ),
          }),
        );

        expect(issues, isEmpty);
      },
    );

    test(
      'fails on missing corrupt wrong dimensions bytes hash and format',
      () async {
        final entries = [
          _entry(id: 'missing', path: 'assets/images/castles/missing.webp'),
          _entry(
            id: 'wrong-bytes',
            path: 'assets/images/castles/wrong-bytes.webp',
          ),
          _entry(
            id: 'wrong-dimensions',
            path: 'assets/images/castles/wrong-dimensions.webp',
          ),
          _entry(
            id: 'wrong-format',
            path: 'assets/images/castles/wrong-format.webp',
          ),
          _entry(
            id: 'wrong-hash',
            path: 'assets/images/castles/wrong-hash.webp',
          ),
        ];
        final issues = await AssetManifestValidator.validateEntriesWithProbe(
          entries,
          _FakeProbe({
            entries[1].path: AssetProbeResult(
              exists: true,
              bytes: entries[1].bytes + 1,
              width: entries[1].width,
              height: entries[1].height,
              format: entries[1].format,
              sha256: entries[1].sha256,
            ),
            entries[2].path: AssetProbeResult(
              exists: true,
              bytes: entries[2].bytes,
              width: 512,
              height: 512,
              format: entries[2].format,
              sha256: entries[2].sha256,
            ),
            entries[3].path: AssetProbeResult(
              exists: true,
              bytes: entries[3].bytes,
              width: entries[3].width,
              height: entries[3].height,
              format: 'unknown',
              sha256: entries[3].sha256,
            ),
            entries[4].path: AssetProbeResult(
              exists: true,
              bytes: entries[4].bytes,
              width: entries[4].width,
              height: entries[4].height,
              format: entries[4].format,
              sha256:
                  '1111111111111111111111111111111111111111111111111111111111111111',
            ),
          }),
        );

        expect(
          issues.map((issue) => '${issue.id}.${issue.field}'),
          containsAll([
            'missing.path',
            'wrong-bytes.bytes',
            'wrong-dimensions.dimensions',
            'wrong-format.format',
            'wrong-hash.sha256',
          ]),
        );
      },
    );

    test('validates thumbnailPath separately when present', () async {
      final entries = [
        _entry(
          id: 'missing-thumbnail',
          thumbnailPath: 'assets/images/castles/missing-thumbnail.webp',
        ),
        _entry(
          id: 'wrong-thumbnail-dimensions',
          thumbnailPath:
              'assets/images/castles/wrong-thumbnail-dimensions.webp',
        ),
        _entry(
          id: 'wrong-thumbnail-format',
          thumbnailPath: 'assets/images/castles/wrong-thumbnail-format.webp',
        ),
        _entry(
          id: 'wrong-thumbnail-bytes',
          thumbnailPath: 'assets/images/castles/wrong-thumbnail-bytes.webp',
        ),
      ];
      final probeResults = <String, AssetProbeResult>{
        for (final entry in entries)
          entry.path: AssetProbeResult(
            exists: true,
            bytes: entry.bytes,
            width: entry.width,
            height: entry.height,
            format: entry.format,
            sha256: entry.sha256,
          ),
        entries[1].thumbnailPath!: const AssetProbeResult(
          exists: true,
          bytes: 24000,
          width: 128,
          height: 128,
          format: 'webp',
          sha256:
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        ),
        entries[2].thumbnailPath!: const AssetProbeResult(
          exists: true,
          bytes: 24000,
          width: 256,
          height: 256,
          format: 'png',
          sha256:
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        ),
        entries[3].thumbnailPath!: AssetProbeResult(
          exists: true,
          bytes: AssetManifestPolicy.defaultPolicy.maxThumbnailBytes + 1,
          width: 256,
          height: 256,
          format: 'webp',
          sha256:
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        ),
      };

      final issues = await AssetManifestValidator.validateEntriesWithProbe(
        entries,
        _FakeProbe(probeResults),
      );

      expect(
        issues.map((issue) => '${issue.id}.${issue.field}: ${issue.message}'),
        containsAll([
          'missing-thumbnail.thumbnailPath: Thumbnail file is missing locally.',
          'wrong-thumbnail-dimensions.thumbnailDimensions: Thumbnail decoded dimensions must be 256x256.',
          'wrong-thumbnail-format.thumbnailFormat: Thumbnail decoded format must match PNG/WebP path extension.',
          'wrong-thumbnail-bytes.thumbnailBytes: Thumbnail byte size is outside policy.',
        ]),
      );
    });

    test('does not probe unapproved inert manifest references', () async {
      final issues = await AssetManifestValidator.validateEntriesWithProbe([
        _entry(
          approved: false,
          license: 'UNAPPROVED-SAMPLE',
          approvedBy: '',
          approvedAt: '',
          thumbnailPath: 'assets/images/castles/castle-bright_thumb.webp',
        ),
      ], const _ThrowingProbe());

      expect(
        issues.map((issue) => issue.field),
        containsAll(['approved', 'license']),
      );
    });
  });

  group('LocalAssetProbe', () {
    late Directory fixtureDirectory;

    setUp(() {
      fixtureDirectory = Directory('.dart_tool/test-assets/local-probe')
        ..createSync(recursive: true);
    });

    tearDown(() {
      if (fixtureDirectory.existsSync()) {
        fixtureDirectory.deleteSync(recursive: true);
      }
    });

    test(
      'reads PNG and WebP headers bytes dimensions format and hash',
      () async {
        final png = _writeFixture(
          fixtureDirectory,
          'one.png',
          _pngFixture(width: 1, height: 2),
        );
        final webp = _writeFixture(
          fixtureDirectory,
          'thumb.webp',
          _webpFixture(width: 256, height: 256),
        );
        const probe = LocalAssetProbe();

        final pngResult = await probe.probe(png.path);
        final webpResult = await probe.probe(webp.path);

        expect(pngResult.exists, isTrue);
        expect(pngResult.bytes, png.lengthSync());
        expect(pngResult.width, 1);
        expect(pngResult.height, 2);
        expect(pngResult.format, 'png');
        expect(
          pngResult.sha256,
          sha256.convert(png.readAsBytesSync()).toString(),
        );

        expect(webpResult.exists, isTrue);
        expect(webpResult.bytes, webp.lengthSync());
        expect(webpResult.width, 256);
        expect(webpResult.height, 256);
        expect(webpResult.format, 'webp');
        expect(
          webpResult.sha256,
          sha256.convert(webp.readAsBytesSync()).toString(),
        );
      },
    );

    test('reports missing and corrupt files behaviorally', () async {
      final corrupt = _writeFixture(
        fixtureDirectory,
        'corrupt.webp',
        Uint8List.fromList([1, 2, 3]),
      );
      const probe = LocalAssetProbe();

      final missing = await probe.probe(
        '${fixtureDirectory.path}/missing.webp',
      );
      final corruptResult = await probe.probe(corrupt.path);

      expect(missing.exists, isFalse);
      expect(corruptResult.exists, isTrue);
      expect(corruptResult.format, 'unknown');
      expect(corruptResult.width, 0);
      expect(corruptResult.height, 0);
      expect(corruptResult.bytes, 3);
    });

    test(
      'drives validator failures for wrong dimensions bytes and hash',
      () async {
        final path = '${fixtureDirectory.path}/validator.webp'.replaceAll(
          '\\',
          '/',
        );
        final file = File(path)
          ..writeAsBytesSync(_webpFixture(width: 4, height: 4));
        final policy = AssetManifestPolicy(
          localPathPrefix: '${fixtureDirectory.path}/'.replaceAll('\\', '/'),
        );

        final issues = await AssetManifestValidator.validateEntriesWithProbe(
          [
            _entry(
              id: 'wrong-dimensions-bytes-hash',
              path: path,
              format: 'webp',
              width: 1024,
              height: 1024,
              bytes: file.lengthSync() + 1,
              sha256:
                  'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            ),
          ],
          const LocalAssetProbe(),
          policy: policy,
        );

        expect(
          issues.map((issue) => '${issue.id}.${issue.field}'),
          containsAll([
            'wrong-dimensions-bytes-hash.bytes',
            'wrong-dimensions-bytes-hash.dimensions',
            'wrong-dimensions-bytes-hash.sha256',
          ]),
        );
      },
    );
  });

  group('AssetManifestValidator catalog and fallback gates', () {
    test(
      'validates catalog and pubspec path agreement without trusting metadata',
      () {
        final entry = _entry();

        expect(
          AssetManifestValidator.validateCatalogAndPubspec(
            entries: [entry],
            catalogPaths: [entry.path],
            pubspecAssets: ['assets/images/'],
          ),
          isEmpty,
        );

        final issues = AssetManifestValidator.validateCatalogAndPubspec(
          entries: [entry],
          catalogPaths: ['assets/images/castles/other.webp'],
          pubspecAssets: ['assets/catalog/'],
        );

        expect(
          issues.map((issue) => issue.field),
          containsAll(['catalog', 'pubspec']),
        );
      },
    );

    test(
      'validates approved thumbnail catalog and pubspec path agreement separately',
      () {
        final entry = _entry(
          thumbnailPath: 'assets/images/castles/castle-bright_thumb.webp',
        );

        expect(
          AssetManifestValidator.validateCatalogAndPubspec(
            entries: [entry],
            catalogPaths: [entry.path, entry.thumbnailPath!],
            pubspecAssets: ['assets/images/'],
          ),
          isEmpty,
        );

        final missingCatalogIssues =
            AssetManifestValidator.validateCatalogAndPubspec(
              entries: [entry],
              catalogPaths: [entry.path],
              pubspecAssets: ['assets/images/'],
            );

        expect(
          missingCatalogIssues.map((issue) => '${issue.id}.${issue.field}'),
          contains('castle-bright.thumbnailCatalog'),
        );
        expect(
          missingCatalogIssues.map((issue) => issue.message),
          contains('Thumbnail path is not referenced by catalog.'),
        );

        final missingPubspecIssues =
            AssetManifestValidator.validateCatalogAndPubspec(
              entries: [entry],
              catalogPaths: [entry.path, entry.thumbnailPath!],
              pubspecAssets: [entry.path],
            );

        expect(
          missingPubspecIssues.map((issue) => '${issue.id}.${issue.field}'),
          contains('castle-bright.thumbnailPubspec'),
        );
        expect(
          missingPubspecIssues.map((issue) => issue.message),
          contains('Thumbnail path is not declared in pubspec assets.'),
        );
      },
    );

    test(
      'allows unapproved inert catalog references without bundled files',
      () {
        final inert = _entry(
          approved: false,
          approvedBy: '',
          approvedAt: '',
          thumbnailPath: 'assets/images/castles/castle-bright_thumb.webp',
        );

        expect(
          AssetManifestValidator.validateCatalogAndPubspec(
            entries: [inert],
            catalogPaths: [inert.path, inert.thumbnailPath!],
            pubspecAssets: ['assets/catalog/'],
          ),
          isEmpty,
        );
      },
    );

    test(
      'keeps bundled sample manifest local unapproved and unavailable for fallback',
      () {
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
          containsAll(['approved', 'license']),
        );
        expect(AssetManifestValidator.approvedUsableAssets(entries), isEmpty);
      },
    );
  });
}

class _ThrowingProbe implements AssetProbe {
  const _ThrowingProbe();

  @override
  Future<AssetProbeResult> probe(String path) {
    throw StateError('Unapproved inert references must not be probed: $path');
  }
}

class _FakeProbe implements AssetProbe {
  const _FakeProbe(this.results);

  final Map<String, AssetProbeResult> results;

  @override
  Future<AssetProbeResult> probe(String path) async {
    return results[path] ?? const AssetProbeResult.missing();
  }
}

File _writeFixture(Directory directory, String name, Uint8List bytes) {
  return File('${directory.path}/$name')..writeAsBytesSync(bytes);
}

Uint8List _pngFixture({required int width, required int height}) {
  return Uint8List.fromList([
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
    0x00,
    0x00,
    0x00,
    0x0d,
    0x49,
    0x48,
    0x44,
    0x52,
    (width >> 24) & 0xff,
    (width >> 16) & 0xff,
    (width >> 8) & 0xff,
    width & 0xff,
    (height >> 24) & 0xff,
    (height >> 16) & 0xff,
    (height >> 8) & 0xff,
    height & 0xff,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
  ]);
}

Uint8List _webpFixture({required int width, required int height}) {
  final bytes = Uint8List(30);
  bytes.setAll(0, 'RIFF'.codeUnits);
  bytes.setAll(8, 'WEBP'.codeUnits);
  bytes.setAll(12, 'VP8X'.codeUnits);
  _writeUint24(bytes, 24, width - 1);
  _writeUint24(bytes, 27, height - 1);
  return bytes;
}

void _writeUint24(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
}

AssetManifestEntry _entry({
  String id = 'castle-bright',
  String path = 'assets/images/castles/castle-bright.webp',
  String? thumbnailPath,
  String sourceTitle = 'Example Public Domain Castle',
  String sourceUrl = 'https://example.org/public-domain-castle',
  String license = 'CC0-1.0',
  String licenseUrl = 'https://creativecommons.org/publicdomain/zero/1.0/',
  String attribution = 'Example Archive, CC0',
  String approvedBy = 'Legal reviewer',
  String approvedAt = '2026-07-21T00:00:00Z',
  String format = 'webp',
  int width = 1024,
  int height = 1024,
  int bytes = 320000,
  String sha256 =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  bool approved = true,
}) {
  return AssetManifestEntry(
    id: id,
    path: path,
    thumbnailPath: thumbnailPath,
    sourceTitle: sourceTitle,
    sourceUrl: sourceUrl,
    license: license,
    licenseUrl: licenseUrl,
    attribution: attribution,
    approved: approved,
    approvedBy: approvedBy,
    approvedAt: approvedAt,
    width: width,
    height: height,
    format: format,
    bytes: bytes,
    sha256: sha256,
  );
}
