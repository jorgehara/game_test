import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/puzzle.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';
import 'package:puzzle_kids/providers/onboarding_provider.dart';
import 'package:puzzle_kids/providers/progress_provider.dart';
import 'package:puzzle_kids/providers/puzzle_game_provider.dart';
import 'package:puzzle_kids/routes/app_routes.dart';
import 'package:puzzle_kids/screens/puzzle_game_screen.dart';
import 'package:puzzle_kids/services/asset_manifest_validator.dart';
import 'package:puzzle_kids/widgets/completion_dialog.dart';
import 'package:puzzle_kids/widgets/puzzle_piece_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders responsive board, tray, controls, and stable keys', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpGame(tester);

    expect(find.byKey(const Key('puzzle-game-screen')), findsOneWidget);
    expect(find.byKey(const Key('puzzle-board')), findsOneWidget);
    expect(find.byKey(const Key('puzzle-tray')), findsOneWidget);
    expect(find.byKey(const Key('puzzle-progress')), findsOneWidget);
    expect(find.text('Progreso 0/4'), findsOneWidget);
    expect(find.byKey(const Key('puzzle-reset-button')), findsOneWidget);
    expect(find.byKey(const Key('puzzle-back-button')), findsOneWidget);
    expect(
      find.byKey(const Key('puzzle-sound-placeholder-button')),
      findsOneWidget,
    );

    for (var index = 0; index < 4; index += 1) {
      expect(find.byKey(Key('puzzle-slot-$index')), findsOneWidget);
    }

    expect(find.byKey(const Key('puzzle-piece-lion_0_0')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Pieza 1 de 4')), findsOneWidget);

    final boardRect = tester.getRect(find.byKey(const Key('puzzle-board')));
    final trayRect = tester.getRect(find.byKey(const Key('puzzle-tray')));

    expect(boardRect.width, greaterThan(360));
    expect(boardRect.height, greaterThan(360));
    expect(boardRect.overlaps(trayRect), isFalse);
    semantics.dispose();
  });

  testWidgets('keeps logical placement visible after resize', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final provider = _provider()..start(puzzleId: 'lion');
    provider.placePiece('lion_0_0');

    await _pumpGame(
      tester,
      provider: provider,
      assetManifest: _castilloManifest(),
    );

    expect(find.text('Progreso 1/4'), findsOneWidget);
    expect(
      find.byKey(const Key('puzzle-placed-piece-lion_0_0')),
      findsOneWidget,
    );

    final firstBoardRect = tester.getRect(
      find.byKey(const Key('puzzle-board')),
    );

    await tester.binding.setSurfaceSize(const Size(900, 700));
    await tester.pumpAndSettle();

    expect(find.text('Progreso 1/4'), findsOneWidget);
    expect(
      find.byKey(const Key('puzzle-placed-piece-lion_0_0')),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.byKey(const Key('puzzle-board'))).size,
      isNot(firstBoardRect.size),
    );
  });

  testWidgets('reset clears progress and returns pieces to tray', (
    tester,
  ) async {
    final provider = _provider()..start(puzzleId: 'lion');
    provider.placePiece('lion_0_0');

    await _pumpGame(
      tester,
      provider: provider,
      assetManifest: _castilloManifest(),
    );

    expect(find.text('Progreso 1/4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('puzzle-reset-button')));
    await tester.pumpAndSettle();

    expect(provider.progressCount, 0);
    expect(find.text('Progreso 0/4'), findsOneWidget);
    expect(find.byKey(const Key('puzzle-piece-lion_0_0')), findsOneWidget);
  });

  testWidgets('shows safe unavailable state when session cannot start', (
    tester,
  ) async {
    final provider = _provider()..start(puzzleId: 'missing');

    await _pumpGame(
      tester,
      provider: provider,
      assetManifest: _castilloManifest(),
    );

    expect(find.byKey(const Key('puzzle-unavailable-state')), findsOneWidget);
    expect(find.text('Puzzle no disponible'), findsOneWidget);
    expect(find.byKey(const Key('puzzle-board')), findsNothing);
  });

  testWidgets('snaps a piece near its correct slot and ignores duplicates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = _provider()..start(puzzleId: 'lion');

    await _pumpGame(tester, provider: provider);

    await _dragPieceToSlot(tester, pieceId: 'lion_0_0', slotIndex: 0);

    expect(provider.progressCount, 1);
    expect(provider.isPlaced('lion_0_0'), isTrue);
    expect(find.text('Progreso 1/4'), findsOneWidget);
    expect(
      find.byKey(const Key('puzzle-placed-piece-lion_0_0')),
      findsOneWidget,
    );

    expect(provider.placePiece('lion_0_0'), isFalse);
    expect(provider.progressCount, 1);
  });

  testWidgets('returns a far or wrong drop without changing progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = _provider()..start(puzzleId: 'lion');

    await _pumpGame(tester, provider: provider);

    await _dragPieceToSlot(tester, pieceId: 'lion_0_0', slotIndex: 3);
    await tester.pump(const Duration(milliseconds: 350));

    expect(provider.progressCount, 0);
    expect(provider.isPlaced('lion_0_0'), isFalse);
    expect(find.text('Progreso 0/4'), findsOneWidget);
    expect(find.byKey(const Key('puzzle-piece-lion_0_0')), findsOneWidget);
    expect(find.byKey(const Key('puzzle-placed-piece-lion_0_0')), findsNothing);
  });

  testWidgets('reset during drag prevents stale placement commit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = _provider()..start(puzzleId: 'lion');

    await _pumpGame(tester, provider: provider);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('puzzle-piece-lion_0_0'))),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('puzzle-reset-button')));
    await tester.pump();

    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('puzzle-slot-0'))),
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(provider.progressCount, 0);
    expect(provider.isPlaced('lion_0_0'), isFalse);
    expect(find.text('Progreso 0/4'), findsOneWidget);
  });

  testWidgets('completion shows accessible dialog once and stores progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressProvider(prefs: prefs);
    final provider = _provider()..start(puzzleId: 'lion');

    await _pumpGame(tester, provider: provider, progress: progress);

    for (final pieceId in ['lion_0_0', 'lion_0_1', 'lion_1_0', 'lion_1_1']) {
      final index = int.parse(pieceId.substring(pieceId.length - 1));
      final rowOffset = pieceId.contains('_1_') ? 2 : 0;
      await _dragPieceToSlot(
        tester,
        pieceId: pieceId,
        slotIndex: rowOffset + index,
      );
    }
    await tester.pumpAndSettle();

    expect(provider.isCompleted, isTrue);
    expect(find.byKey(const Key('completion-dialog')), findsOneWidget);
    expect(find.text('¡Lo lograste!'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(progress.isCompleted('lion'), isTrue);

    expect(provider.placePiece('lion_0_0'), isFalse);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('completion-dialog')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('completion-dialog')), findsNothing);
  });

  testWidgets('completion dialog uses reduced motion fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) => const Scaffold(
              body: Center(
                child: CompletionDialog(
                  puzzleName: 'Lion',
                  onContinue: _noop,
                  onReplay: _noop,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('completion-static-success')), findsOneWidget);
    expect(find.byKey(const Key('completion-confetti')), findsNothing);
  });

  testWidgets('drag onboarding appears once with skip action', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final onboarding = OnboardingProvider(prefs: prefs);

    await _pumpGame(tester, onboarding: onboarding);

    expect(find.byKey(const Key('drag-onboarding-dialog')), findsOneWidget);
    expect(find.text('Arrastrá y soltá'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Omitir'));
    await tester.pumpAndSettle();

    expect(onboarding.shouldShowDragOnboarding, isFalse);
    expect(find.byKey(const Key('drag-onboarding-dialog')), findsNothing);
  });

  testWidgets('drag onboarding understood action persists and hides dialog', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final onboarding = OnboardingProvider(prefs: prefs);

    await _pumpGame(tester, onboarding: onboarding);

    expect(find.byKey(const Key('drag-onboarding-dialog')), findsOneWidget);
    expect(find.text('Entendido'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(onboarding.shouldShowDragOnboarding, isFalse);
    expect(prefs.getBool('pk.dragOnboardingSeen'), isTrue);
    expect(find.byKey(const Key('drag-onboarding-dialog')), findsNothing);

    await tester.pump();

    expect(find.byKey(const Key('drag-onboarding-dialog')), findsNothing);
  });

  testWidgets('drag onboarding back dismisses and stores first-run state', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final onboarding = OnboardingProvider(prefs: prefs);

    await _pumpGame(tester, onboarding: onboarding);

    expect(find.byKey(const Key('drag-onboarding-dialog')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(onboarding.shouldShowDragOnboarding, isFalse);
    expect(prefs.getBool('pk.dragOnboardingSeen'), isTrue);
    expect(find.byKey(const Key('drag-onboarding-dialog')), findsNothing);

    await tester.pump();

    expect(find.byKey(const Key('drag-onboarding-dialog')), findsNothing);
  });

  testWidgets('board, tray, and drag overlay share the approved 2x2 source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = _providerWithCatalog(_castilloCatalog())
      ..start(puzzleId: 'castillo-princesa');
    provider.placePiece('castillo-princesa_0_0');

    await _pumpGame(
      tester,
      provider: provider,
      assetManifest: _castilloManifest(),
    );

    expect(
      find.byKey(const Key('puzzle-placed-piece-castillo-princesa_0_0')),
      findsOneWidget,
    );

    final assetNames = tester
        .widgetList<PuzzlePieceTile>(find.byType(PuzzlePieceTile))
        .map((tile) => tile.imageSource?.assetPath)
        .nonNulls
        .toSet();

    expect(assetNames, {'assets/images/castles/castillo-princesa.webp'});

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const Key('puzzle-piece-castillo-princesa_0_1')),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('puzzle-dragging-piece-castillo-princesa_0_1')),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'renders approved 3x3 source in the tray without network images',
    (tester) async {
      final provider = _providerWithCatalog(
        _castilloCatalog(grid: GridSpec(rows: 3, columns: 3)),
      )..start(puzzleId: 'castillo-princesa');

      await _pumpGame(
        tester,
        provider: provider,
        assetManifest: _castilloManifest(),
      );

      expect(
        tester
            .widgetList<PuzzlePieceTile>(find.byType(PuzzlePieceTile))
            .where((tile) => tile.imageSource != null),
        hasLength(9),
      );
      expect(
        tester
            .widgetList<PuzzlePieceTile>(find.byType(PuzzlePieceTile))
            .map((tile) => tile.imageSource?.assetPath)
            .nonNulls
            .toSet(),
        {'assets/images/castles/castillo-princesa.webp'},
      );
    },
  );

  testWidgets('renders atlas full images through local Image.asset pieces', (
    tester,
  ) async {
    final provider = _providerWithCatalog(_atlasCatalog())
      ..start(puzzleId: 'atlas-astronaut');

    await _pumpGame(
      tester,
      provider: provider,
      assetManifest: _atlasManifest(),
    );

    final imageSources = tester
        .widgetList<PuzzlePieceTile>(find.byType(PuzzlePieceTile))
        .map((tile) => tile.imageSource)
        .nonNulls
        .toList(growable: false);

    expect(imageSources, hasLength(9));
    expect(imageSources.map((source) => source.assetPath).toSet(), {
      'assets/images/space/atlas-astronaut.webp',
    });
    expect(imageSources.every((source) => source.approved), isTrue);
    expect(tester.widgetList<Image>(find.byType(Image)), isNotEmpty);
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => image.image)
          .whereType<AssetImage>()
          .map((image) => image.assetName)
          .toSet(),
      {'assets/images/space/atlas-astronaut.webp'},
    );
  });

  testWidgets(
    'keeps numbered fallback for unavailable or missing approved art',
    (tester) async {
      await _pumpGame(tester);

      expect(find.byType(Image), findsNothing);
      expect(find.text('1'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Pieza 1 de 4')), findsOneWidget);
    },
  );

  test('static policy forbids network puzzle piece rendering', () {
    for (final path in [
      'lib/screens/puzzle_game_screen.dart',
      'lib/widgets/puzzle_board.dart',
      'lib/widgets/puzzle_piece_tile.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(source, isNot(contains('Image.network')));
      expect(source, isNot(contains('NetworkImage')));
    }
  });
}

Future<void> _pumpGame(
  WidgetTester tester, {
  PuzzleGameProvider? provider,
  ProgressProvider? progress,
  OnboardingProvider? onboarding,
  bool disableAnimations = false,
  List<AssetManifestEntry>? assetManifest,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final defaultOnboarding = OnboardingProvider(prefs: prefs)..markLoaded();
  if (onboarding == null) {
    await defaultOnboarding.completeDragOnboarding();
  }
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PuzzleGameProvider>.value(
          value: provider ?? _provider(),
        ),
        ChangeNotifierProvider<ProgressProvider>.value(
          value: progress ?? ProgressProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<OnboardingProvider>.value(
          value: onboarding ?? defaultOnboarding,
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: PuzzleGameScreen(
            key: ObjectKey(provider),
            assetManifest: assetManifest,
            existingAssetPaths: assetManifest == null
                ? const {}
                : assetManifest
                      .expand((entry) => [entry.path, entry.thumbnailPath])
                      .nonNulls
                      .toSet(),
          ),
        ),
        routes: {AppRoutes.selection: (_) => const SizedBox.shrink()},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _dragPieceToSlot(
  WidgetTester tester, {
  required String pieceId,
  required int slotIndex,
}) async {
  final pieceFinder = find.byKey(Key('puzzle-piece-$pieceId'));
  final slotFinder = find.byKey(Key('puzzle-slot-$slotIndex'));

  await tester.dragFrom(
    tester.getCenter(pieceFinder),
    tester.getCenter(slotFinder) - tester.getCenter(pieceFinder),
  );
  await tester.pumpAndSettle();
}

PuzzleGameProvider _provider() {
  return _providerWithCatalog(_catalog());
}

PuzzleGameProvider _providerWithCatalog(List<Puzzle> catalog) {
  return PuzzleGameProvider(
    catalogLoader: () => catalog,
    shuffler: _identityShuffler,
  );
}

List<Puzzle> _catalog() {
  return [
    Puzzle(
      id: 'lion',
      name: 'Lion',
      category: PuzzleCategory.animals,
      imagePath: 'assets/images/animals/lion.png',
      difficulty: PuzzleDifficulty.level(2),
      grid: GridSpec(rows: 2, columns: 2),
    ),
  ];
}

List<Puzzle> _castilloCatalog({GridSpec? grid}) {
  final puzzleGrid = grid ?? GridSpec(rows: 2, columns: 2);
  return [
    Puzzle(
      id: 'castillo-princesa',
      name: 'Castillo princesa',
      category: PuzzleCategory.castles,
      imagePath: 'assets/images/castles/castillo-princesa.webp',
      thumbnailPath: 'assets/images/castles/castillo-princesa_thumb.webp',
      difficulty: PuzzleDifficulty.level(puzzleGrid.pieceCount == 9 ? 4 : 2),
      grid: puzzleGrid,
    ),
  ];
}

List<Puzzle> _atlasCatalog() {
  return [
    Puzzle(
      id: 'atlas-astronaut',
      name: 'Astronauta espacial',
      category: PuzzleCategory.space,
      imagePath: 'assets/images/space/atlas-astronaut.webp',
      thumbnailPath: 'assets/images/space/atlas-astronaut_thumb.webp',
      difficulty: PuzzleDifficulty.level(4),
      grid: GridSpec(rows: 3, columns: 3),
    ),
  ];
}

List<AssetManifestEntry> _castilloManifest() {
  return const [
    AssetManifestEntry(
      id: 'castillo-princesa',
      path: 'assets/images/castles/castillo-princesa.webp',
      thumbnailPath: 'assets/images/castles/castillo-princesa_thumb.webp',
      sourceTitle: 'Castillo princesa',
      sourceUrl: 'project-owned://assets/images/castillo-princesa.png',
      license: 'PROJECT-OWNED',
      licenseUrl: 'project-owned://LICENSE',
      attribution:
          'User-provided PROJECT-OWNED artwork for Puzzle Kids; optimized offline from local original assets/images/castillo-princesa.png.',
      approved: true,
      approvedBy: 'Puzzle Kids asset review',
      approvedAt: '2026-07-22T00:00:00.000Z',
      width: 1024,
      height: 1024,
      format: 'webp',
      bytes: 131770,
      sha256:
          '92b69c509f6baac96d9348dea093259dcb4d058eefad6186e1db97277c9929fc',
    ),
  ];
}

List<AssetManifestEntry> _atlasManifest() {
  return const [
    AssetManifestEntry(
      id: 'atlas-astronaut',
      path: 'assets/images/space/atlas-astronaut.webp',
      thumbnailPath: 'assets/images/space/atlas-astronaut_thumb.webp',
      sourceTitle: 'User-provided project-owned atlas - varios-assets.png',
      sourceUrl: 'project-owned://assets/images/varios-assets.png',
      license: 'PROJECT-OWNED',
      licenseUrl: 'project-owned://LICENSE',
      attribution:
          'User/project owner confirmed ownership and authorized using/publishing derived Puzzle Kids atlas assets on 2026-07-22.',
      approved: true,
      approvedBy: 'Puzzle Kids project owner',
      approvedAt: '2026-07-22T00:00:00Z',
      width: 1024,
      height: 1024,
      format: 'webp',
      bytes: 86628,
      sha256:
          '6e80ea4818b5e3bf1777481fb925d24a9d74fc57380185210b46f94ea80ff59d',
    ),
  ];
}

List<T> _identityShuffler<T>(List<T> pieces, {required int seed}) {
  return List.unmodifiable(pieces);
}

void _noop() {}
