import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/puzzle.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';
import 'package:puzzle_kids/services/puzzle_catalog_service.dart';

void main() {
  group('PuzzleCatalogService', () {
    test('exposes more than 20 unique inert child-safe metadata entries', () {
      final puzzles = PuzzleCatalogService.all();

      expect(puzzles.length, greaterThan(20));
      expect(
        puzzles.map((puzzle) => puzzle.id).toSet(),
        hasLength(puzzles.length),
      );
      expect(
        puzzles.map((puzzle) => puzzle.category).toSet(),
        containsAll([
          PuzzleCategory.castles,
          PuzzleCategory.princesses,
          PuzzleCategory.unicorns,
        ]),
      );
      expect(
        puzzles.map((puzzle) => puzzle.category).toSet(),
        PuzzleCategory.values.toSet(),
      );
      expect(puzzles.map((puzzle) => puzzle.difficulty.level).toSet(), {2, 4});
      expect(
        puzzles.map((puzzle) => puzzle.grid.pieceCount).toSet(),
        containsAll([4, 9]),
      );
      expect(puzzles.every((puzzle) => puzzle.name.trim().isNotEmpty), isTrue);
      expect(
        puzzles.every((puzzle) => puzzle.levelLabel.trim().isNotEmpty),
        isTrue,
      );
      expect(
        puzzles.every((puzzle) => puzzle.placeholderLabel.trim().isNotEmpty),
        isTrue,
      );
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

    test('exposes only 2x2 and 3x3 puzzles as playable', () {
      final playable = PuzzleCatalogService.playable();

      expect(playable, isNotEmpty);
      expect(
        playable.every((puzzle) => puzzle.grid.isSupportedForGeneration),
        isTrue,
      );
      expect(
        playable.every(
          (puzzle) =>
              (puzzle.grid.rows == 2 && puzzle.grid.columns == 2) ||
              (puzzle.grid.rows == 3 && puzzle.grid.columns == 3),
        ),
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
      expect(
        puzzles.first.thumbnailPath,
        'assets/images/animals/lion_thumb.png',
      );
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
    thumbnailPath: imagePath.replaceFirst('.png', '_thumb.png'),
    placeholderSeed: 1,
    placeholderLabel: 'Figura de prueba',
    difficulty: PuzzleDifficulty.level(2),
    grid: grid ?? GridSpec(rows: 2, columns: 2),
  );
}
