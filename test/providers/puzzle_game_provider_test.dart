import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/puzzle.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';
import 'package:puzzle_kids/models/puzzle_piece.dart';
import 'package:puzzle_kids/providers/puzzle_game_provider.dart';

void main() {
  group('PuzzleGameProvider', () {
    test('filters playable puzzles to supported 2x2 and 3x3 grids', () {
      final provider = PuzzleGameProvider(catalogLoader: _mixedCatalog);

      expect(provider.playablePuzzles.map((puzzle) => puzzle.id), [
        'lion',
        'elephant',
      ]);
    });

    test(
      'starts a supported 2x2 puzzle with shuffled pieces and empty progress',
      () {
        final provider = PuzzleGameProvider(
          catalogLoader: _mixedCatalog,
          shuffler: _reverseShuffler,
        );

        final started = provider.start(puzzleId: 'lion');

        expect(started, isTrue);
        expect(provider.status, PuzzleGameStatus.ready);
        expect(provider.currentPuzzle?.id, 'lion');
        expect(provider.pieces, hasLength(4));
        expect(provider.pieces.map((piece) => piece.id), [
          'lion_1_1',
          'lion_1_0',
          'lion_0_1',
          'lion_0_0',
        ]);
        expect(provider.piecesInTray, provider.pieces);
        expect(provider.placedPieceIds, isEmpty);
        expect(provider.progressCount, 0);
        expect(provider.progressRatio, 0);
        expect(provider.isCompleted, isFalse);
      },
    );

    test('starts a supported 3x3 puzzle', () {
      final provider = PuzzleGameProvider(catalogLoader: _mixedCatalog);

      final started = provider.start(puzzleId: 'elephant');

      expect(started, isTrue);

      expect(provider.currentPuzzle?.grid, GridSpec(rows: 3, columns: 3));
      expect(provider.pieces, hasLength(9));
      expect(provider.progressRatio, 0);
    });

    test(
      'rejects unsupported or missing puzzle metadata without playable state',
      () {
        final provider = PuzzleGameProvider(catalogLoader: _mixedCatalog);

        expect(provider.start(puzzleId: 'giraffe'), isFalse);
        expect(provider.status, PuzzleGameStatus.unavailable);
        expect(provider.currentPuzzle, isNull);
        expect(provider.pieces, isEmpty);

        expect(provider.start(puzzleId: 'missing'), isFalse);
        expect(provider.status, PuzzleGameStatus.unavailable);
        expect(provider.currentPuzzle, isNull);
        expect(provider.pieces, isEmpty);
      },
    );

    test(
      'places pieces logically, updates tray/progress, and completes once',
      () {
        final provider = PuzzleGameProvider(
          catalogLoader: _mixedCatalog,
          shuffler: _identityShuffler,
        )..start(puzzleId: 'lion');

        final firstPiece = provider.pieces.first;

        expect(provider.placePiece(firstPiece.id), isTrue);
        expect(provider.isPlaced(firstPiece.id), isTrue);
        expect(provider.placedPieceIds, {firstPiece.id});
        expect(
          provider.placedPositions[firstPiece.id],
          firstPiece.correctPosition,
        );
        expect(provider.piecesInTray.map((piece) => piece.id), [
          'lion_0_1',
          'lion_1_0',
          'lion_1_1',
        ]);
        expect(provider.progressCount, 1);
        expect(provider.progressRatio, 0.25);
        expect(provider.isCompleted, isFalse);

        for (final piece in provider.piecesInTray.toList()) {
          expect(provider.placePiece(piece.id), isTrue);
        }

        expect(provider.status, PuzzleGameStatus.completed);
        expect(provider.isCompleted, isTrue);
        expect(provider.progressCount, 4);
        expect(provider.progressRatio, 1);
      },
    );

    test(
      'ignores duplicate placement, unknown pieces, and post-completion placement',
      () {
        final provider = PuzzleGameProvider(
          catalogLoader: _mixedCatalog,
          shuffler: _identityShuffler,
        )..start(puzzleId: 'lion');
        final firstPiece = provider.pieces.first;

        expect(provider.placePiece(firstPiece.id), isTrue);
        expect(provider.placePiece(firstPiece.id), isFalse);
        expect(provider.placePiece('missing-piece'), isFalse);
        expect(provider.progressCount, 1);

        for (final piece in provider.piecesInTray.toList()) {
          provider.placePiece(piece.id);
        }

        expect(provider.isCompleted, isTrue);
        expect(provider.placePiece(firstPiece.id), isFalse);
        expect(provider.progressCount, 4);
      },
    );

    test(
      'reset clears placements and keeps the current supported puzzle playable',
      () {
        final provider = PuzzleGameProvider(
          catalogLoader: _mixedCatalog,
          shuffler: _reverseShuffler,
        )..start(puzzleId: 'lion');
        provider.placePiece(provider.pieces.first.id);

        provider.reset();

        expect(provider.status, PuzzleGameStatus.ready);
        expect(provider.currentPuzzle?.id, 'lion');
        expect(provider.placedPieceIds, isEmpty);
        expect(provider.placedPositions, isEmpty);
        expect(provider.progressCount, 0);
        expect(provider.progressRatio, 0);
        expect(provider.piecesInTray, provider.pieces);
        expect(provider.pieces.map((piece) => piece.id), [
          'lion_1_1',
          'lion_1_0',
          'lion_0_1',
          'lion_0_0',
        ]);
      },
    );

    test('reset is safe before any session exists', () {
      final provider = PuzzleGameProvider(catalogLoader: _mixedCatalog);

      provider.reset();

      expect(provider.status, PuzzleGameStatus.idle);
      expect(provider.currentPuzzle, isNull);
      expect(provider.pieces, isEmpty);
      expect(provider.progressRatio, 0);
    });
  });
}

List<Puzzle> _mixedCatalog() {
  return [
    _puzzle(id: 'lion', grid: GridSpec(rows: 2, columns: 2), level: 2),
    _puzzle(id: 'elephant', grid: GridSpec(rows: 3, columns: 3), level: 4),
    _puzzle(id: 'giraffe', grid: GridSpec(rows: 1, columns: 2), level: 1),
    _puzzle(id: 'train', grid: GridSpec(rows: 2, columns: 3), level: 3),
  ];
}

List<PuzzlePiece> _identityShuffler(
  List<PuzzlePiece> pieces, {
  required int seed,
}) {
  return List.unmodifiable(pieces);
}

List<PuzzlePiece> _reverseShuffler(
  List<PuzzlePiece> pieces, {
  required int seed,
}) {
  return List.unmodifiable(pieces.reversed);
}

Puzzle _puzzle({
  required String id,
  required GridSpec grid,
  required int level,
}) {
  return Puzzle(
    id: id,
    name: id,
    category: PuzzleCategory.animals,
    imagePath: 'assets/images/animals/$id.png',
    difficulty: PuzzleDifficulty.level(level),
    grid: grid,
  );
}
