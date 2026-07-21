import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/puzzle.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';
import 'package:puzzle_kids/services/puzzle_catalog_service.dart';

void main() {
  group('PuzzleCatalogService', () {
    test('exposes exactly 20 unique inert puzzle metadata entries', () {
      final puzzles = PuzzleCatalogService.all();

      expect(puzzles, hasLength(20));
      expect(puzzles.map((puzzle) => puzzle.id).toSet(), hasLength(20));
      expect(
        puzzles.map((puzzle) => puzzle.category).toSet(),
        PuzzleCategory.values.toSet(),
      );
      expect(puzzles.map((puzzle) => puzzle.difficulty.level).toSet(), {
        1,
        2,
        3,
        4,
        5,
      });
      expect(
        puzzles.map((puzzle) => puzzle.grid.pieceCount).toSet(),
        containsAll([2, 4, 6, 9, 12]),
      );
      expect(puzzles.every((puzzle) => puzzle.name.trim().isNotEmpty), isTrue);
      expect(
        puzzles.every(
          (puzzle) => puzzle.imagePath.startsWith('assets/images/'),
        ),
        isTrue,
      );
      expect(
        puzzles.every((puzzle) => puzzle.imagePath.endsWith('.png')),
        isTrue,
      );
    });

    test('returns immutable catalog metadata without loading asset files', () {
      final puzzles = PuzzleCatalogService.all();

      expect(
        () => puzzles.add(_validPuzzle(id: 'extra')),
        throwsUnsupportedError,
      );
      expect(puzzles.first.imagePath, 'assets/images/animals/lion.png');
    });

    test(
      'validates catalog duplicates and invalid metadata deterministically',
      () {
        final valid = PuzzleCatalogService.all();

        expect(() => PuzzleCatalogService.validate(valid), returnsNormally);
        expect(
          () => PuzzleCatalogService.validate([valid.first, valid.first]),
          throwsArgumentError,
        );
        expect(
          () => PuzzleCatalogService.validate([
            _validPuzzle(id: 'bad grid', grid: GridSpec(rows: 1, columns: 1)),
          ]),
          throwsArgumentError,
        );
        expect(
          () => PuzzleCatalogService.validate([
            _validPuzzle(id: 'bad-path', imagePath: 'lion.png'),
          ]),
          throwsArgumentError,
        );
      },
    );
  });
}

Puzzle _validPuzzle({
  String id = 'lion-copy',
  String imagePath = 'assets/images/animals/lion-copy.png',
  GridSpec? grid,
}) {
  return Puzzle(
    id: id,
    name: 'Lion Copy',
    category: PuzzleCategory.animals,
    imagePath: imagePath,
    difficulty: PuzzleDifficulty.level(2),
    grid: grid ?? GridSpec(rows: 2, columns: 2),
  );
}
