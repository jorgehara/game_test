import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/puzzle.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';
import 'package:puzzle_kids/models/puzzle_piece.dart';
import 'package:puzzle_kids/services/puzzle_piece_generator.dart';
import 'package:puzzle_kids/services/puzzle_shuffler.dart';

void main() {
  group('PuzzleShuffler', () {
    test(
      'returns the same order for the same seed without mutating source',
      () {
        final pieces = PuzzlePieceGenerator.generate(
          _puzzle(grid: GridSpec(rows: 3, columns: 3)),
        );
        final originalIds = pieces.map((piece) => piece.id).toList();

        final firstShuffle = PuzzleShuffler.shuffle(pieces, seed: 7);
        final secondShuffle = PuzzleShuffler.shuffle(pieces, seed: 7);

        expect(firstShuffle, secondShuffle);
        expect(pieces.map((piece) => piece.id), originalIds);
        expect(identical(firstShuffle, pieces), isFalse);
      },
    );

    test('uses the seed to produce reproducible different permutations', () {
      final pieces = PuzzlePieceGenerator.generate(
        _puzzle(grid: GridSpec(rows: 3, columns: 3)),
      );

      final seedSeven = PuzzleShuffler.shuffle(pieces, seed: 7);
      final seedEleven = PuzzleShuffler.shuffle(pieces, seed: 11);

      expect(
        seedSeven.map((piece) => piece.id),
        isNot(seedEleven.map((piece) => piece.id)),
      );
    });

    test(
      'avoids solved order for playable grids when shuffle matches solved order',
      () {
        final pieces = PuzzlePieceGenerator.generate(
          _puzzle(grid: GridSpec(rows: 2, columns: 2)),
        );

        final shuffled = PuzzleShuffler.shuffle(pieces, seed: 60);

        expect(_isSolved(shuffled), isFalse);
        expect(
          shuffled.map((piece) => piece.id).toSet(),
          pieces.map((piece) => piece.id).toSet(),
        );
      },
    );

    test('handles empty and one-piece edge cases explicitly', () {
      final single = PuzzlePieceGenerator.generate(
        _puzzle(grid: GridSpec(rows: 2, columns: 2)),
      ).take(1).toList();

      expect(PuzzleShuffler.shuffle(const [], seed: 1), isEmpty);
      expect(PuzzleShuffler.shuffle(single, seed: 1), single);
    });
  });
}

bool _isSolved(List<PuzzlePiece> pieces) {
  for (var index = 0; index < pieces.length; index++) {
    if (pieces[index].correctIndex != index) {
      return false;
    }
  }

  return true;
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
