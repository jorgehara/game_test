import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current;

  group('asset package and offline policy gates', () {
    test('documents and measures the current project-owned offline pack', () {
      final manifest = _assetManifest(root);

      expect(manifest, hasLength(9));
      expect(
        manifest.every((entry) => entry['license'] == 'PROJECT-OWNED'),
        isTrue,
      );
      expect(
        manifest.every(
          (entry) => entry['sourceUrl'].toString().startsWith(
            'project-owned://assets/source/puzzles/',
          ),
        ),
        isTrue,
      );
      expect(
        manifest.every(
          (entry) => entry['approvedBy'] == 'Puzzle Kids project owner',
        ),
        isTrue,
      );
      expect(manifest.every((entry) => entry['format'] == 'png'), isTrue);
      expect(
        manifest.every((entry) => entry['dimensions']['width'] == 512),
        isTrue,
      );
      expect(
        manifest.every((entry) => entry['dimensions']['height'] == 512),
        isTrue,
      );

      var totalBytes = 0;
      final fullPaths = <String>{};
      final thumbnailPaths = <String>{};

      for (final entry in manifest) {
        final path = entry['path'] as String;
        final thumbnailPath = entry['thumbnailPath'] as String;
        fullPaths.add(path);
        thumbnailPaths.add(thumbnailPath);

        final full = File('${root.path}/$path');
        final thumbnail = File('${root.path}/$thumbnailPath');
        expect(full.existsSync(), isTrue, reason: path);
        expect(thumbnail.existsSync(), isTrue, reason: thumbnailPath);
        expect(full.lengthSync(), entry['bytes'], reason: path);
        expect(thumbnail.lengthSync(), lessThanOrEqualTo(80 * 1024));
        totalBytes += full.lengthSync() + thumbnail.lengthSync();
      }

      expect(fullPaths, hasLength(9));
      expect(thumbnailPaths, hasLength(9));
      expect(totalBytes, 52639);
      expect(_read(root, 'README.md'), contains('52,639 bytes'));
      expect(_read(root, 'NOTICE'), contains('52,639 bytes'));
    });

    test('keeps release packaging assumptions offline', () {
      final pubspec = _read(root, 'pubspec.yaml');
      expect(pubspec, contains('- assets/catalog/'));
      expect(pubspec, contains('- assets/images/'));

      final mainManifest = _read(
        root,
        'android/app/src/main/AndroidManifest.xml',
      );
      expect(mainManifest, isNot(contains('android.permission.INTERNET')));

      final source = _dartSource(root);
      expect(source, isNot(contains('Image.network')));
      expect(source, isNot(contains('NetworkImage')));
      expect(source, isNot(contains('precacheImage')));

      final readme = _read(root, 'README.md');
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
  });
}

List<Map<String, dynamic>> _assetManifest(Directory root) {
  final decoded =
      jsonDecode(_read(root, 'assets/catalog/asset_licenses.json'))
          as List<dynamic>;
  return decoded.cast<Map<String, dynamic>>();
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
