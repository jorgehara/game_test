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
import 'package:puzzle_kids/widgets/completion_dialog.dart';
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

    await _pumpGame(tester, provider: provider);

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

    await _pumpGame(tester, provider: provider);

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

    await _pumpGame(tester, provider: provider);

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
}

Future<void> _pumpGame(
  WidgetTester tester, {
  PuzzleGameProvider? provider,
  ProgressProvider? progress,
  OnboardingProvider? onboarding,
  bool disableAnimations = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final defaultOnboarding = OnboardingProvider(prefs: prefs)..markLoaded();
  if (onboarding == null) {
    await defaultOnboarding.completeDragOnboarding();
  }
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
          child: const PuzzleGameScreen(),
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
  return PuzzleGameProvider(
    catalogLoader: _catalog,
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

List<T> _identityShuffler<T>(List<T> pieces, {required int seed}) {
  return List.unmodifiable(pieces);
}

void _noop() {}
