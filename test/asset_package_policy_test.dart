import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current;

  group('asset package and offline policy gates', () {
    test('documents and measures the current project-owned offline pack', () {
      final manifest = _assetManifest(root);
      final atlas = manifest
          .where((entry) => (entry['id'] as String).startsWith('atlas-'))
          .toList(growable: false);

      expect(manifest, hasLength(19));
      expect(atlas, hasLength(9));
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
          (entry) =>
              entry['sourceUrl'] ==
              'project-owned://assets/images/varios-assets.png',
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

      expect(fullPaths, hasLength(19));
      expect(thumbnailPaths, hasLength(19));
      expect(atlasFullBytes, 858126);
      expect(atlasThumbnailBytes, 174656);
      expect(totalBytes, 1231513);
      expect(_read(root, 'README.md'), contains('1,231,513 bytes'));
      expect(_read(root, 'NOTICE'), contains('1,231,513 bytes'));

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
      expect(pubspec, contains('- assets/catalog/'));
      expect(pubspec, contains('- assets/images/'));
      expect(
        pubspec,
        contains('- assets/images/castles/castillo-princesa.webp'),
      );
      expect(
        pubspec,
        contains('- assets/images/castles/castillo-princesa_thumb.webp'),
      );
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

    test('does not ship runtime atlas cropping or pre-sliced piece assets', () {
      final generatedAtlasAssets = Directory('${root.path}/assets/images')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.replaceAll(r'\', '/'))
          .where((path) => path.contains('/atlas-'))
          .toList(growable: false);

      expect(generatedAtlasAssets, hasLength(18));
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

String _dartSource(Directory root) {
  final lib = Directory('${root.path}/lib');
  return lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');
}

String _read(Directory root, String path) =>
    File('${root.path}/$path').readAsStringSync();
