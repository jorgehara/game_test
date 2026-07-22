import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/puzzle.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';
import 'package:puzzle_kids/models/puzzle_piece.dart';
import 'package:puzzle_kids/services/puzzle_piece_generator.dart';

void main() {
  group('PuzzlePieceGenerator', () {
    test(
      'generates 2x2 pieces in row-major solved order with normalized crops',
      () {
        final pieces = PuzzlePieceGenerator.generate(
          _puzzle(grid: GridSpec(rows: 2, columns: 2)),
        );

        expect(pieces, hasLength(4));
        expect(pieces.map((piece) => piece.id), [
          'lion_0_0',
          'lion_0_1',
          'lion_1_0',
          'lion_1_1',
        ]);
        expect(pieces.map((piece) => piece.correctIndex), [0, 1, 2, 3]);
        expect(pieces.map((piece) => piece.correctPosition.row), [0, 0, 1, 1]);
        expect(pieces.map((piece) => piece.correctPosition.column), [
          0,
          1,
          0,
          1,
        ]);
        expect(
          pieces.map((piece) => piece.currentPosition),
          pieces.map((piece) => piece.correctPosition),
        );
        expect(pieces[0].crop.left, 0);
        expect(pieces[0].crop.top, 0);
        expect(pieces[0].crop.width, 0.5);
        expect(pieces[0].crop.height, 0.5);
        expect(pieces[3].crop.left, 0.5);
        expect(pieces[3].crop.top, 0.5);
        expect(pieces[3].crop.right, 1);
        expect(pieces[3].crop.bottom, 1);
      },
    );

    test(
      'generates 3x3 pieces with unique ids, positions, and full unit-square coverage',
      () {
        final pieces = PuzzlePieceGenerator.generate(
          _puzzle(grid: GridSpec(rows: 3, columns: 3)),
        );

        expect(pieces, hasLength(9));
        expect(pieces.map((piece) => piece.id).toSet(), hasLength(9));
        expect(
          pieces.map((piece) => piece.correctPosition.index).toSet(),
          hasLength(9),
        );
        expect(pieces.first.id, 'lion_0_0');
        expect(pieces.last.id, 'lion_2_2');
        expect(
          pieces.fold<double>(
            0,
            (sum, piece) => sum + piece.crop.width * piece.crop.height,
          ),
          closeTo(1, 0.000000001),
        );
        expect(pieces.map((piece) => piece.crop.left).toSet(), {
          0.0,
          1 / 3,
          2 / 3,
        });
        expect(pieces.map((piece) => piece.crop.top).toSet(), {
          0.0,
          1 / 3,
          2 / 3,
        });
      },
    );

    test('is repeatable for the same puzzle metadata and grid', () {
      final puzzle = _puzzle(grid: GridSpec(rows: 2, columns: 2));

      expect(
        PuzzlePieceGenerator.generate(puzzle),
        PuzzlePieceGenerator.generate(puzzle),
      );
    });

    test('generates 1x1 topology with all edges flat', () {
      final pieces = PuzzlePieceGenerator.generate(
        _puzzle(grid: GridSpec(rows: 1, columns: 1)),
      );

      expect(pieces, hasLength(1));
      expect(pieces.single.id, 'lion_0_0');
      expect(pieces.single.edges, PuzzlePieceEdges.allFlat);
    });

    test('generates deterministic mirrored 2x2 topology', () {
      final puzzle = _puzzle(grid: GridSpec(rows: 2, columns: 2));
      final firstRun = PuzzlePieceGenerator.generate(puzzle);
      final secondRun = PuzzlePieceGenerator.generate(puzzle);

      expect(
        firstRun.map((piece) => piece.edges),
        secondRun.map((piece) => piece.edges),
      );
      _expectOuterEdgesFlat(firstRun);
      _expectNeighborsComplementary(firstRun);
    });

    test('generates deterministic mirrored 3x3 topology', () {
      final puzzle = _puzzle(grid: GridSpec(rows: 3, columns: 3));
      final firstRun = PuzzlePieceGenerator.generate(puzzle);
      final secondRun = PuzzlePieceGenerator.generate(puzzle);

      expect(
        firstRun.map((piece) => piece.edges),
        secondRun.map((piece) => piece.edges),
      );
      _expectOuterEdgesFlat(firstRun);
      _expectNeighborsComplementary(firstRun);
    });

    test('rejects non-playable MVP generation grids', () {
      expect(
        () => PuzzlePieceGenerator.generate(
          _puzzle(grid: GridSpec(rows: 2, columns: 3)),
        ),
        throwsArgumentError,
      );
    });
  });
}

void _expectOuterEdgesFlat(List<PuzzlePiece> pieces) {
  for (final piece in pieces) {
    final position = piece.correctPosition;
    final grid = position.grid;
    if (position.row == 0) {
      expect(piece.edges.top, PuzzlePieceEdge.flat, reason: piece.id);
    }
    if (position.column == grid.columns - 1) {
      expect(piece.edges.right, PuzzlePieceEdge.flat, reason: piece.id);
    }
    if (position.row == grid.rows - 1) {
      expect(piece.edges.bottom, PuzzlePieceEdge.flat, reason: piece.id);
    }
    if (position.column == 0) {
      expect(piece.edges.left, PuzzlePieceEdge.flat, reason: piece.id);
    }
  }
}

void _expectNeighborsComplementary(List<PuzzlePiece> pieces) {
  final byPosition = {
    for (final piece in pieces)
      '${piece.correctPosition.row}:${piece.correctPosition.column}': piece,
  };

  for (final piece in pieces) {
    final position = piece.correctPosition;
    final right = byPosition['${position.row}:${position.column + 1}'];
    if (right != null) {
      expect(
        piece.edges.right.complement,
        right.edges.left,
        reason: '${piece.id} -> ${right.id}',
      );
    }

    final below = byPosition['${position.row + 1}:${position.column}'];
    if (below != null) {
      expect(
        piece.edges.bottom.complement,
        below.edges.top,
        reason: '${piece.id} -> ${below.id}',
      );
    }
  }
}

Puzzle _puzzle({required GridSpec grid}) {
  return Puzzle(
    id: 'lion',
    name: 'Lion',
    category: PuzzleCategory.animals,
    imagePath: 'assets/images/animals/lion.png',
    difficulty: PuzzleDifficulty.level(2),
    grid: grid,
  );
}
