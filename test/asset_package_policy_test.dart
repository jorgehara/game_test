import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current;

  group('asset package and offline policy gates', () {
    test('documents and measures the current project-owned offline pack', () {
      final manifest = _assetManifest(root);
      final atlas = manifest
          .where((entry) => (entry['id'] as String).startsWith('atlas-'))
          .toList(growable: false);

      expect(manifest, hasLength(21));
      expect(atlas, hasLength(11));
      expect(
        manifest.every((entry) => entry['license'] == 'PROJECT-OWNED'),
        isTrue,
      );
      expect(
        manifest.every(
          (entry) =>
              entry['sourceUrl'].toString().startsWith('project-owned://'),
        ),
        isTrue,
      );
      expect(
        manifest.every(
          (entry) => entry['approvedBy'] == 'Puzzle Kids project owner',
        ),
        isTrue,
      );
      expect(manifest.map((entry) => entry['format']).toSet(), {'png', 'webp'});
      expect(
        atlas.every(
          (entry) => (entry['sourceUrl'] as String).startsWith(
            'project-owned://assets/images/',
          ),
        ),
        isTrue,
      );
      expect(atlas.every((entry) => entry['format'] == 'webp'), isTrue);
      expect(atlas.every((entry) => entry['approved'] == true), isTrue);
      expect(
        atlas.every(
          (entry) =>
              RegExp(r'^[0-9a-f]{64}$').hasMatch(entry['sha256'] as String),
        ),
        isTrue,
      );

      var totalBytes = 0;
      var atlasFullBytes = 0;
      var atlasThumbnailBytes = 0;
      final fullPaths = <String>{};
      final thumbnailPaths = <String>{};

      for (final entry in manifest) {
        final path = entry['path'] as String;
        final thumbnailPath = entry['thumbnailPath'] as String;
        final isAtlas = (entry['id'] as String).startsWith('atlas-');
        fullPaths.add(path);
        thumbnailPaths.add(thumbnailPath);

        final full = File('${root.path}/$path');
        final thumbnail = File('${root.path}/$thumbnailPath');
        expect(full.existsSync(), isTrue, reason: path);
        expect(thumbnail.existsSync(), isTrue, reason: thumbnailPath);
        expect(full.lengthSync(), entry['bytes'], reason: path);
        expect(thumbnail.lengthSync(), lessThanOrEqualTo(80 * 1024));
        expect(full.lengthSync(), lessThanOrEqualTo(800 * 1024));
        expect(path, startsWith('assets/images/'));
        expect(thumbnailPath, startsWith('assets/images/'));
        expect(path, isNot(contains('varios-assets.png')));
        expect(thumbnailPath, isNot(contains('varios-assets.png')));
        if (isAtlas) {
          expect(entry['dimensions']['width'], 1024, reason: path);
          expect(entry['dimensions']['height'], 1024, reason: path);
          expect(thumbnailPath, endsWith('_thumb.webp'));
          atlasFullBytes += full.lengthSync();
          atlasThumbnailBytes += thumbnail.lengthSync();
        }
        totalBytes += full.lengthSync() + thumbnail.lengthSync();
      }

      expect(fullPaths, hasLength(21));
      expect(thumbnailPaths, hasLength(21));
      expect(atlasFullBytes, 1013262);
      expect(atlasThumbnailBytes, 201966);
      expect(totalBytes, 1500020);
      expect(_read(root, 'README.md'), contains('1,500,020 bytes'));
      expect(_read(root, 'NOTICE'), contains('1,500,020 bytes'));

      final castillo = manifest.singleWhere(
        (entry) => entry['id'] == 'castillo-princesa',
      );
      expect(castillo['path'], 'assets/images/castles/castillo-princesa.webp');
      expect(
        castillo['thumbnailPath'],
        'assets/images/castles/castillo-princesa_thumb.webp',
      );
      expect(castillo['bytes'], 131770);
      expect(castillo['dimensions']['width'], 1024);
      expect(castillo['dimensions']['height'], 1024);
      expect(
        castillo['sha256'],
        '92b69c509f6baac96d9348dea093259dcb4d058eefad6186e1db97277c9929fc',
      );
    });

    test('keeps atlas extraction metadata auditable and explicit', () {
      final metadata = _atlasMetadata(root);
      final outputs = (metadata['outputs'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final source = metadata['source'] as Map<String, dynamic>;
      final generation = metadata['generation'] as Map<String, dynamic>;

      expect(source['path'], 'assets/images/varios-assets.png');
      expect(source['license'], 'PROJECT-OWNED');
      expect(
        source['provenance'],
        contains('confirmed ownership and authorized using/publishing'),
      );
      expect(source['bundling'], contains('do not stage'));
      expect(source['dimensions'], {'width': 1402, 'height': 1122});
      expect(generation['cropPolicy'], contains('Explicit 3x3 panel boxes'));
      expect(outputs, hasLength(9));

      for (final output in outputs) {
        final panelBox = (output['panelBox'] as List<dynamic>).cast<int>();
        final cropBox = (output['cropBox'] as List<dynamic>).cast<int>();
        final full = output['full'] as Map<String, dynamic>;
        final thumbnail = output['thumbnail'] as Map<String, dynamic>;

        expect(panelBox, hasLength(4), reason: output['id'] as String);
        expect(cropBox, hasLength(4), reason: output['id'] as String);
        expect(full['path'], startsWith('assets/images/'));
        expect(thumbnail['path'], endsWith('_thumb.webp'));
        expect(full['width'], 1024);
        expect(full['height'], 1024);
        expect(thumbnail['width'], 256);
        expect(thumbnail['height'], 256);
        expect(full['bytes'], lessThanOrEqualTo(800 * 1024));
        expect(thumbnail['bytes'], lessThanOrEqualTo(80 * 1024));
        expect(full['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(thumbnail['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      }
    });

    test('keeps release packaging assumptions offline', () {
      final pubspec = _read(root, 'pubspec.yaml');
      final pubspecAssets = _pubspecAssets(root);
      expect(pubspec, contains('- assets/catalog/'));
      expect(pubspecAssets, isNot(contains('assets/images/')));
      expect(pubspec, contains('- assets/images/castles/'));
      expect(pubspec, contains('- assets/images/vehicles/'));
      expect(pubspec, contains('- assets/images/professions/'));
      expect(pubspec, isNot(contains('varios-assets.png')));

      final mainManifest = _read(
        root,
        'android/app/src/main/AndroidManifest.xml',
      );
      expect(mainManifest, isNot(contains('android.permission.INTERNET')));

      final source = _dartSource(root);
      expect(source, isNot(contains('Image.network')));
      expect(source, isNot(contains('NetworkImage')));
      expect(source, isNot(contains('precacheImage')));
      expect(source, isNot(contains('assets/images/varios-assets.png')));

      final readme = _read(root, 'README.md');
      final notice = _read(root, 'NOTICE');
      final puzzles = _read(root, 'assets/catalog/puzzles.json');
      final licenses = _assetManifest(root);

      expect(puzzles, isNot(contains('varios-assets.png')));
      expect(
        licenses.every(
          (entry) =>
              !(entry['path'] as String).contains('varios-assets.png') &&
              !(entry['thumbnailPath'] as String).contains('varios-assets.png'),
        ),
        isTrue,
      );
      expect(readme, contains('varios-assets.png'));
      expect(notice, contains('varios-assets.png'));
      expect(readme, contains('offline atlas extraction pipeline'));
      expect(readme, contains('Original atlas is not bundled'));
      expect(notice, contains('Original atlas is not bundled'));
      expect(readme, contains('Stale/pre-current-pack evidence only'));
      expect(
        readme,
        contains(
          'Do not claim this APK includes the current starter pack until rebuilt',
        ),
      );
      expect(readme, contains('build apk --release --split-per-abi'));
      expect(readme, contains('install --release'));
      expect(
        readme,
        contains('RAM, startup, and 60fps/frame pacing were not measured'),
      );
    });

    test('keeps cropped user PNGs staging-only and out of bundle policy', () {
      const rootStagingPngs = {
        'astro.png',
        'camiones.png',
        'car.png',
        'castillo.png',
        'castillo-princesa.png',
        'dinosaurios.png',
        'doctora.png',
        'princesa.png',
        'animales.png',
      };

      final gitignore = _read(root, '.gitignore');
      final pubspec = _read(root, 'pubspec.yaml');
      final pubspecAssets = _pubspecAssets(root);
      final provenance = _croppedProvenance(root);
      final sources = (provenance['sources'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(sources, hasLength(9));
      expect(pubspecAssets, isNot(contains('assets/images/')));
      expect(gitignore, contains('assets/images/varios assets.png'));
      expect(pubspec, isNot(contains('assets/images/varios assets.png')));
      for (final name in rootStagingPngs) {
        expect(gitignore, contains('assets/images/$name'), reason: name);
        expect(pubspec, isNot(contains('assets/images/$name')), reason: name);
      }

      expect(
        sources.map((entry) => entry['source']['path']).toSet(),
        rootStagingPngs.map((name) => 'assets/images/$name').toSet(),
      );
      expect(
        sources.every((entry) => entry['provenance'] == 'user-provided'),
        isTrue,
      );
      expect(
        sources.every(
          (entry) => (entry['sourceUri'] as String).startsWith(
            'project-owned://assets/images/',
          ),
        ),
        isTrue,
      );
      expect(
        sources.where((entry) => entry['mappingStatus'] == 'approved'),
        hasLength(8),
      );
      expect(
        sources.where(
          (entry) => entry['mappingStatus'] == 'preserved-published',
        ),
        hasLength(1),
      );
    });

    test(
      'records PR2 promoted derivative inventory with runtime catalog mapping',
      () {
        final provenance = _croppedProvenance(root);
        final sources = (provenance['sources'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final manifest = _assetManifest(root);
        final puzzles = _puzzles(root);
        const expectedRuntimeIds = {
          'astro.png': ('atlas-astronaut', 'space'),
          'camiones.png': ('atlas-vehicles-friends', 'vehicles'),
          'car.png': ('atlas-race-car', 'vehicles'),
          'castillo.png': ('castle-bright', 'castles'),
          'castillo-princesa.png': ('castillo-princesa', 'castles'),
          'dinosaurios.png': ('atlas-dinosaurs', 'dinosaurs'),
          'doctora.png': ('atlas-doctor', 'professions'),
          'princesa.png': ('atlas-princess-garden', 'princesses'),
          'animales.png': ('atlas-animals', 'animals'),
        };
        final fullPaths = <String>{};
        final thumbnailPaths = <String>{};

        for (final entry in sources) {
          final source = entry['source'] as Map<String, dynamic>;
          final full = entry['full'] as Map<String, dynamic>;
          final thumbnail = entry['thumbnail'] as Map<String, dynamic>;
          final sourceName = (source['path'] as String).split('/').last;
          final expected = expectedRuntimeIds[sourceName];
          final manifestEntry = manifest.singleWhere(
            (item) => item['id'] == expected?.$1,
            orElse: () => fail('Missing manifest entry for $sourceName'),
          );
          final puzzle = puzzles.singleWhere(
            (item) => item['id'] == expected?.$1,
            orElse: () => fail('Missing puzzle catalog entry for $sourceName'),
          );

          fullPaths.add(full['path'] as String);
          thumbnailPaths.add(thumbnail['path'] as String);

          expect(expected, isNotNull, reason: sourceName);
          expect(entry['outputId'], expected!.$1, reason: sourceName);
          expect(entry['category'], expected.$2, reason: sourceName);
          expect(full['path'], startsWith('assets/images/'));
          expect(full['path'], isNot(endsWith('-pending.webp')));
          expect(thumbnail['path'], isNot(endsWith('-pending_thumb.webp')));
          expect(full['format'], 'webp');
          expect(thumbnail['format'], 'webp');
          expect(full['dimensions'], {'width': 1024, 'height': 1024});
          expect(thumbnail['dimensions'], {'width': 256, 'height': 256});
          _expectExactFileMetadata(root, source, format: 'png');
          _expectExactFileMetadata(root, full, format: 'webp');
          _expectExactFileMetadata(root, thumbnail, format: 'webp');
          expect(manifestEntry['path'], full['path'], reason: sourceName);
          expect(
            manifestEntry['thumbnailPath'],
            thumbnail['path'],
            reason: sourceName,
          );
          expect(manifestEntry['sourceUrl'], entry['sourceUri']);
          expect(manifestEntry['sourceProvenance'], 'user-provided');
          expect(manifestEntry['category'], expected.$2, reason: sourceName);
          expect(manifestEntry['bytes'], full['bytes'], reason: sourceName);
          expect(manifestEntry['sha256'], full['sha256'], reason: sourceName);
          expect(
            manifestEntry['thumbnail']['bytes'],
            thumbnail['bytes'],
            reason: sourceName,
          );
          expect(puzzle['image'], full['path'], reason: sourceName);
          expect(puzzle['thumbnail'], thumbnail['path'], reason: sourceName);
          expect(puzzle['category'], expected.$2, reason: sourceName);
        }

        expect(sources, hasLength(expectedRuntimeIds.length));
        expect(fullPaths, hasLength(9));
        expect(thumbnailPaths, hasLength(9));
        expect(fullPaths.length + thumbnailPaths.length, 18);
        expect(
          fullPaths.contains('assets/images/castles/castillo-princesa.webp'),
          isTrue,
        );
        expect(fullPaths.any((path) => path.contains('_piece')), isFalse);

        final catalog = _read(root, 'assets/catalog/asset_licenses.json');
        expect(catalog, isNot(contains('-pending.webp')));
        expect(catalog, contains('project-owned://assets/images/astro.png'));
      },
    );

    test('does not ship runtime atlas cropping or pre-sliced piece assets', () {
      final generatedAtlasAssets = Directory('${root.path}/assets/images')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.replaceAll(r'\', '/'))
          .where((path) => path.contains('/atlas-'))
          .where((path) => !path.contains('-pending'))
          .toList(growable: false);

      expect(generatedAtlasAssets, hasLength(22));
      expect(
        generatedAtlasAssets.every((path) => path.endsWith('.webp')),
        isTrue,
      );
      expect(
        generatedAtlasAssets.every(
          (path) => path.endsWith('_thumb.webp') || !path.contains('_thumb'),
        ),
        isTrue,
      );
      expect(
        generatedAtlasAssets.any(
          (path) => RegExp(r'_(piece|row|col|r\d|c\d)').hasMatch(path),
        ),
        isFalse,
      );
    });

    test('keeps the jigsaw renderer pure and offline-only', () {
      final shapeSource = _read(root, 'lib/widgets/puzzle_piece_shape.dart');
      final tileSource = _read(root, 'lib/widgets/puzzle_piece_tile.dart');

      expect(shapeSource, isNot(contains('Random')));
      expect(shapeSource, isNot(contains('DateTime')));
      expect(shapeSource, isNot(contains('Timer')));
      expect(shapeSource, isNot(contains('Image.')));
      expect(shapeSource, isNot(contains('Network')));
      expect(tileSource, contains('Image.asset'));
      expect(tileSource, isNot(contains('Image.network')));
      expect(tileSource, isNot(contains('NetworkImage')));
    });

    test('documents deterministic rollback and preserves published assets', () {
      final replacements = _read(
        root,
        'assets/source/puzzles/atlas-replacements.md',
      );
      const expectedRows = {
        'atlas-astronaut': 'astro.png',
        'atlas-dinosaurs': 'dinosaurios.png',
        'atlas-doctor': 'doctora.png',
        'atlas-race-car': 'car.png',
        'castle-bright': 'castillo.png',
        'atlas-animals': 'animales.png',
        'atlas-vehicles-friends': 'camiones.png',
        'atlas-princess-garden': 'princesa.png',
        'castillo-princesa': 'castillo-princesa.png',
      };

      expect(replacements, contains('Base/reference: `3d98dcb`'));
      expect(replacements, contains('git checkout 3d98dcb'));
      expect(
        replacements,
        contains(
          'Unrelated atlas entries intentionally unchanged: `atlas-airplane`, `atlas-truck`, `atlas-emergency-vehicles`, `atlas-princess-castle`.',
        ),
      );
      for (final row in expectedRows.entries) {
        expect(replacements, contains('`${row.key}`'), reason: row.key);
        expect(replacements, contains(row.value), reason: row.key);
      }
      expect(replacements, contains('preserve published asset'));
      expect(replacements, contains('unchanged'));
      expect(
        replacements,
        contains(
          '92b69c509f6baac96d9348dea093259dcb4d058eefad6186e1db97277c9929fc',
        ),
      );
    });
  });
}

List<Map<String, dynamic>> _assetManifest(Directory root) {
  final decoded =
      jsonDecode(_read(root, 'assets/catalog/asset_licenses.json'))
          as List<dynamic>;
  return decoded.cast<Map<String, dynamic>>();
}

Map<String, dynamic> _atlasMetadata(Directory root) {
  return jsonDecode(
        _read(root, 'assets/source/puzzles/atlas_crop_metadata.json'),
      )
      as Map<String, dynamic>;
}

Map<String, dynamic> _croppedProvenance(Directory root) {
  return jsonDecode(_read(root, 'assets/source/puzzles/provenance.json'))
      as Map<String, dynamic>;
}

List<Map<String, dynamic>> _puzzles(Directory root) {
  final decoded =
      jsonDecode(_read(root, 'assets/catalog/puzzles.json')) as List<dynamic>;
  return decoded.cast<Map<String, dynamic>>();
}

void _expectExactFileMetadata(
  Directory root,
  Map<String, dynamic> metadata, {
  required String format,
}) {
  final file = File('${root.path}/${metadata['path']}');
  expect(file.existsSync(), isTrue, reason: metadata['path'] as String);
  expect(metadata['format'], format, reason: metadata['path'] as String);
  expect(
    metadata['bytes'],
    file.lengthSync(),
    reason: metadata['path'] as String,
  );
  expect(
    metadata['sha256'],
    sha256.convert(file.readAsBytesSync()).toString(),
    reason: metadata['path'] as String,
  );
}

String _dartSource(Directory root) {
  final lib = Directory('${root.path}/lib');
  return lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');
}

Set<String> _pubspecAssets(Directory root) {
  final assets = <String>{};
  var inFlutter = false;
  var inAssets = false;
  for (final line in File('${root.path}/pubspec.yaml').readAsLinesSync()) {
    if (line.startsWith('flutter:')) {
      inFlutter = true;
      inAssets = false;
      continue;
    }
    if (!inFlutter) continue;
    if (line.startsWith('  assets:')) {
      inAssets = true;
      continue;
    }
    if (inAssets) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ')) {
        assets.add(trimmed.substring(2));
      } else if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
        break;
      }
    }
  }
  return assets;
}

String _read(Directory root, String path) =>
    File('${root.path}/$path').readAsStringSync();
