import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Puzzle Kids launcher icon', () {
    const root = 'android/app/src/main';
    const manifestPath = '$root/AndroidManifest.xml';
    const adaptiveDir = '$root/res/mipmap-anydpi-v26';
    const sourceIconPath = 'assets/source/icon/puzzle-kids-icon.svg';

    const expectedLegacyIcons = <String, int>{
      '$root/res/mipmap-mdpi/ic_launcher.png': 48,
      '$root/res/mipmap-mdpi/ic_launcher_round.png': 48,
      '$root/res/mipmap-hdpi/ic_launcher.png': 72,
      '$root/res/mipmap-hdpi/ic_launcher_round.png': 72,
      '$root/res/mipmap-xhdpi/ic_launcher.png': 96,
      '$root/res/mipmap-xhdpi/ic_launcher_round.png': 96,
      '$root/res/mipmap-xxhdpi/ic_launcher.png': 144,
      '$root/res/mipmap-xxhdpi/ic_launcher_round.png': 144,
      '$root/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      '$root/res/mipmap-xxxhdpi/ic_launcher_round.png': 192,
    };

    test(
      'manifest preserves Puzzle Kids label and references icon resources',
      () {
        final manifest = File(manifestPath).readAsStringSync();

        expect(manifest, contains('android:label="Puzzle Kids"'));
        expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
        expect(
          manifest,
          contains('android:roundIcon="@mipmap/ic_launcher_round"'),
        );
      },
    );

    test(
      'legacy launcher pngs exist for every density with expected sizes',
      () {
        for (final entry in expectedLegacyIcons.entries) {
          final file = File(entry.key);

          expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
          expect(_pngDimensions(file), (
            width: entry.value,
            height: entry.value,
          ));
        }
      },
    );

    test('adaptive icons use project-owned foreground and background', () {
      final adaptiveIcon = File(
        '$adaptiveDir/ic_launcher.xml',
      ).readAsStringSync();
      final adaptiveRoundIcon = File(
        '$adaptiveDir/ic_launcher_round.xml',
      ).readAsStringSync();

      for (final xml in [adaptiveIcon, adaptiveRoundIcon]) {
        expect(xml, contains('@drawable/ic_launcher_foreground'));
        expect(xml, contains('@color/ic_launcher_background'));
        expect(xml, isNot(contains('@mipmap/ic_launcher')));
      }
    });

    test('icon source documents project-owned origin', () {
      final source = File(sourceIconPath).readAsStringSync();
      final readme = File('README.md').readAsStringSync();
      final notice = File('NOTICE').readAsStringSync();

      expect(source, contains('PROJECT-OWNED'));
      expect(source, contains('Puzzle Kids'));
      expect(readme, contains('assets/source/icon/puzzle-kids-icon.svg'));
      expect(readme, contains('PROJECT-OWNED'));
      expect(notice, contains('PROJECT-OWNED'));
    });

    test('legacy icons are not the Flutter default launcher assets', () {
      const flutterDefaultFingerprints = <String>{
        '442:iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAMAAABg3Ak=',
        '544:iVBORw0KGgoAAAANSUhEUgAAAEgAAABICAMAAABiM0M=',
        '721:iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRoc=',
        '1031:iVBORw0KGgoAAAANSUhEUgAAAJAAAACQCAMAAADQmBI=',
        '1443:iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAMAAABlApw=',
      };

      for (final path in expectedLegacyIcons.keys) {
        final fingerprint = _pngFingerprint(File(path).readAsBytesSync());

        expect(
          flutterDefaultFingerprints,
          isNot(contains(fingerprint)),
          reason: path,
        );
      }
    });
  });
}

({int width, int height}) _pngDimensions(File file) {
  final bytes = file.readAsBytesSync();
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];

  expect(bytes.take(8), signature, reason: '${file.path} is not a PNG');

  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  return (width: data.getUint32(16), height: data.getUint32(20));
}

String _pngFingerprint(List<int> bytes) {
  final prefix = bytes.take(32).toList(growable: false);
  return '${bytes.length}:${base64Encode(prefix)}';
}
