import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/services/puzzle_asset_manifest_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PuzzleAssetManifestLoader', () {
    test('loads only approved local bundled manifest entries', () async {
      final entries = await PuzzleAssetManifestLoader.loadApproved();
      const mappedIds = {
        'atlas-astronaut',
        'atlas-vehicles-friends',
        'atlas-race-car',
        'castle-bright',
        'castillo-princesa',
        'atlas-dinosaurs',
        'atlas-doctor',
        'atlas-princess-garden',
        'atlas-animals',
      };

      expect(entries, hasLength(21));
      expect(entries.every((entry) => entry.approved), isTrue);
      expect(
        entries.every(
          (entry) => entry.sourceUrl.startsWith('project-owned://'),
        ),
        isTrue,
      );
      expect(entries.every((entry) => entry.thumbnailPath != null), isTrue);
      expect(
        entries.where((entry) => mappedIds.contains(entry.id)),
        hasLength(9),
      );
      for (final entry in entries.where(
        (entry) => mappedIds.contains(entry.id),
      )) {
        expect(entry.path, startsWith('assets/images/'), reason: entry.id);
        expect(entry.path, endsWith('.webp'), reason: entry.id);
        expect(entry.thumbnailPath, endsWith('_thumb.webp'), reason: entry.id);
        expect(entry.width, 1024, reason: entry.id);
        expect(entry.height, 1024, reason: entry.id);
        expect(entry.format, 'webp', reason: entry.id);
        expect(entry.sourceUrl, startsWith('project-owned://assets/images/'));
        expect(entry.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      }
    });

    test('filters unapproved entries from the runtime manifest', () async {
      final entries = await PuzzleAssetManifestLoader.loadApproved(
        bundle: _ManifestAssetBundle(
          jsonEncode([
            _entryJson(id: 'castle-bright'),
            _entryJson(id: 'unapproved-sample', approved: false),
          ]),
        ),
      );

      expect(entries.map((entry) => entry.id), ['castle-bright']);
      expect(PuzzleAssetManifestLoader.existingPathsFor(entries), {
        'assets/images/castles/castle-bright.png',
        'assets/images/castles/castle-bright_thumb.png',
      });
    });
  });
}

class _ManifestAssetBundle extends CachingAssetBundle {
  _ManifestAssetBundle(this.manifestJson);

  final String manifestJson;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(manifestJson));
    return ByteData.sublistView(bytes);
  }
}

Map<String, Object?> _entryJson({required String id, bool approved = true}) {
  return {
    'id': id,
    'path': 'assets/images/castles/$id.png',
    'thumbnailPath': 'assets/images/castles/${id}_thumb.png',
    'sourceTitle': 'Puzzle Kids original vector illustration - $id',
    'sourceUrl': 'project-owned://assets/source/puzzles/$id.svg',
    'license': 'PROJECT-OWNED',
    'licenseUrl': 'project-owned://LICENSE',
    'attribution': 'Puzzle Kids PROJECT-OWNED original local vector artwork.',
    'approved': approved,
    'approvedBy': approved ? 'Puzzle Kids project owner' : '',
    'approvedAt': approved ? '2026-07-22T00:00:00Z' : '',
    'dimensions': {'width': 512, 'height': 512},
    'format': 'png',
    'bytes': 4096,
    'sha256':
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  };
}
