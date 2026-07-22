import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:puzzle_kids/providers/app_shell_provider.dart';
import 'package:puzzle_kids/providers/onboarding_provider.dart';
import 'package:puzzle_kids/providers/progress_provider.dart';
import 'package:puzzle_kids/providers/puzzle_game_provider.dart';
import 'package:puzzle_kids/providers/settings_provider.dart';
import 'package:puzzle_kids/routes/app_routes.dart';
import 'package:puzzle_kids/screens/puzzle_game_screen.dart';
import 'package:puzzle_kids/screens/puzzle_selection_screen.dart';
import 'package:puzzle_kids/services/asset_manifest_validator.dart';
import 'package:puzzle_kids/theme/pk_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders accessible premium puzzle cards with metadata', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpSelection(tester);
    await _scrollUntilVisible(tester, 'Castillo brillante');

    expect(find.text('Elegí tu puzzle'), findsOneWidget);
    expect(find.text('Castillo brillante'), findsOneWidget);
    expect(find.text('Castillos'), findsWidgets);
    expect(find.text('Nivel 2'), findsWidgets);
    expect(find.text('0/4 piezas'), findsWidgets);
    expect(
      find.bySemanticsLabel('Imagen segura de Castillo brillante'),
      findsOneWidget,
    );
    expect(
      _visibleAssetImageNames(tester),
      contains('assets/images/castles/castle-bright_thumb.webp'),
    );

    final playButton = find.widgetWithText(
      FilledButton,
      'Jugar Castillo brillante',
    );
    expect(playButton, findsOneWidget);
    expect(tester.getSize(playButton).height, greaterThanOrEqualTo(48));

    semantics.dispose();
  });

  testWidgets('starts selected puzzle within the selection flow', (
    tester,
  ) async {
    final provider = PuzzleGameProvider();

    await _pumpSelection(tester, provider: provider);
    await _scrollUntilVisible(tester, 'Jugar Castillo brillante');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Jugar Castillo brillante'),
    );
    await tester.pumpAndSettle();

    expect(provider.currentPuzzle?.id, 'castle-bright');
    expect(find.byKey(const Key('puzzle-game-screen')), findsOneWidget);
  });

  testWidgets('uses safe fallback for unapproved or non-pack assets', (
    tester,
  ) async {
    await _pumpSelection(
      tester,
      assetManifest: [
        _entry(id: 'castle-bright', approved: false),
        _entry(id: 'not-in-catalog'),
      ],
      existingAssetPaths: {
        'assets/images/castles/castle-bright.png',
        'assets/images/castles/castle-bright_thumb.png',
        'assets/images/castles/not-in-catalog.png',
        'assets/images/castles/not-in-catalog_thumb.png',
      },
    );
    await _scrollUntilVisible(tester, 'Castillo brillante');

    expect(find.text('Castillo brillante'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Imagen segura de Castillo brillante'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('keeps selection usable when manifest loading fails', (
    tester,
  ) async {
    await _pumpSelection(
      tester,
      assetBundle: _ManifestAssetBundle(loadError: 'loader failed'),
    );
    await _scrollUntilVisible(tester, 'Castillo brillante');

    expect(find.text('Elegí tu puzzle'), findsOneWidget);
    expect(find.text('Castillo brillante'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('loads approved manifest entries in normal app flow', (
    tester,
  ) async {
    await _pumpSelection(
      tester,
      assetBundle: _ManifestAssetBundle(
        manifestJson: jsonEncode([
          _entryJson(id: 'castle-bright'),
          _entryJson(id: 'princess-crown'),
          _entryJson(id: 'unicorn-cloud'),
          _entryJson(id: 'unapproved-sample', approved: false),
        ]),
      ),
    );
    await _scrollUntilVisible(tester, 'Castillo brillante');

    expect(
      _visibleAssetImageNames(tester),
      contains('assets/images/castles/castle-bright_thumb.png'),
    );
  });

  testWidgets('loads atlas thumbnails from approved bundled manifest entries', (
    tester,
  ) async {
    await _pumpSelection(
      tester,
      assetManifest: [_atlasEntry(id: 'atlas-doctor')],
      existingAssetPaths: {
        'assets/images/professions/atlas-doctor.webp',
        'assets/images/professions/atlas-doctor_thumb.webp',
      },
    );
    await _scrollUntilVisible(tester, 'Médica amable');

    expect(find.text('Médica amable'), findsWidgets);
    expect(find.text('Profesiones'), findsWidgets);
    expect(
      find.bySemanticsLabel('Imagen segura de Médica amable'),
      findsOneWidget,
    );

    expect(
      _visibleAssetImageNames(tester),
      contains('assets/images/professions/atlas-doctor_thumb.webp'),
    );
  });

  testWidgets(
    'keeps atlas selection local when approval metadata is unusable',
    (tester) async {
      await _pumpSelection(
        tester,
        assetManifest: [_atlasEntry(id: 'atlas-doctor', approved: false)],
        existingAssetPaths: {
          'assets/images/professions/atlas-doctor.webp',
          'assets/images/professions/atlas-doctor_thumb.webp',
        },
      );
      await _scrollUntilVisible(tester, 'Médica amable');

      expect(find.text('Médica amable'), findsWidgets);
      expect(find.byType(Image), findsNothing);
    },
  );
}

Future<void> _scrollUntilVisible(WidgetTester tester, String text) async {
  final textFinder = find.text(text);
  if (textFinder.evaluate().isNotEmpty) return;

  await tester.scrollUntilVisible(
    textFinder.first,
    240,
    scrollable: find.byType(Scrollable).last,
  );
}

Set<String> _visibleAssetImageNames(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .whereType<ResizeImage>()
      .map((image) => image.imageProvider)
      .whereType<AssetImage>()
      .map((image) => image.assetName)
      .toSet();
}

Future<void> _pumpSelection(
  WidgetTester tester, {
  PuzzleGameProvider? provider,
  List<AssetManifestEntry>? assetManifest,
  Set<String> existingAssetPaths = const {},
  AssetBundle? assetBundle,
}) async {
  await tester.binding.setSurfaceSize(const Size(760, 20000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final prefs = await SharedPreferences.getInstance();
  final onboarding = OnboardingProvider(prefs: prefs)..markLoaded();
  await onboarding.completeDragOnboarding();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppShellProvider>(create: (_) => const AppShellProvider()),
        ChangeNotifierProvider<PuzzleGameProvider>.value(
          value: provider ?? PuzzleGameProvider(),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (_) => ProgressProvider(prefs: prefs)..markLoaded(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(prefs: prefs)..markLoaded(),
        ),
        ChangeNotifierProvider<OnboardingProvider>.value(value: onboarding),
      ],
      child: MaterialApp(
        theme: PkTheme.light(),
        home: PuzzleSelectionScreen(
          assetManifest: assetManifest,
          existingAssetPaths: existingAssetPaths,
          assetBundle: assetBundle,
        ),
        routes: {AppRoutes.game: (_) => const PuzzleGameScreen()},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ManifestAssetBundle extends CachingAssetBundle {
  _ManifestAssetBundle({this.manifestJson = '[]', this.loadError});

  final String manifestJson;
  final String? loadError;

  @override
  Future<ByteData> load(String key) async {
    final error = loadError;
    if (error != null) throw StateError(error);
    final bytes = Uint8List.fromList(utf8.encode(manifestJson));
    return ByteData.sublistView(bytes);
  }
}

Map<String, Object?> _entryJson({required String id, bool approved = true}) {
  final category = switch (id) {
    'princess-crown' => 'princesses',
    'unicorn-cloud' => 'unicorns',
    'dragon-kite' => 'dinosaurs',
    'mermaid-lagoon' => 'ocean',
    'rocket-moon' => 'space',
    'fox-forest' => 'animals',
    'rainbow-bus' => 'vehicles',
    'berry-cupcake' => 'fruits',
    _ => 'castles',
  };
  return {
    'id': id,
    'path': 'assets/images/$category/$id.png',
    'thumbnailPath': 'assets/images/$category/${id}_thumb.png',
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

AssetManifestEntry _entry({required String id, bool approved = true}) {
  return AssetManifestEntry.fromJson(_entryJson(id: id, approved: approved));
}

AssetManifestEntry _atlasEntry({required String id, bool approved = true}) {
  return AssetManifestEntry.fromJson({
    'id': id,
    'path': 'assets/images/professions/atlas-doctor.webp',
    'thumbnailPath': 'assets/images/professions/atlas-doctor_thumb.webp',
    'sourceTitle': 'User-provided project-owned atlas - varios-assets.png',
    'sourceUrl': 'project-owned://assets/images/varios-assets.png',
    'license': 'PROJECT-OWNED',
    'licenseUrl': 'project-owned://LICENSE',
    'attribution':
        'User/project owner confirmed ownership and authorized using/publishing derived Puzzle Kids atlas assets on 2026-07-22.',
    'approved': approved,
    'approvedBy': 'Puzzle Kids project owner',
    'approvedAt': '2026-07-22T00:00:00Z',
    'dimensions': {'width': 1024, 'height': 1024},
    'format': 'webp',
    'bytes': 88796,
    'sha256':
        '5589e7042b82c642e289ca55fc94791d68843cb871330636969f89570d7ecbb4',
  });
}
