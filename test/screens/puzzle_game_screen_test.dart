import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/puzzle.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';
import 'package:puzzle_kids/providers/puzzle_game_provider.dart';
import 'package:puzzle_kids/screens/puzzle_game_screen.dart';

void main() {
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
}

Future<void> _pumpGame(
  WidgetTester tester, {
  PuzzleGameProvider? provider,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<PuzzleGameProvider>.value(
      value: provider ?? _provider(),
      child: const MaterialApp(home: PuzzleGameScreen()),
    ),
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
