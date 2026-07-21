import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/puzzle.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';

void main() {
  group('Puzzle', () {
    test('accepts valid inert metadata without loading assets', () {
      final puzzle = Puzzle(
        id: 'lion',
        name: 'Lion',
        category: PuzzleCategory.animals,
        imagePath: 'assets/images/animals/lion.png',
        difficulty: PuzzleDifficulty.level(2),
        grid: GridSpec(rows: 2, columns: 2),
      );

      expect(puzzle.id, 'lion');
      expect(puzzle.name, 'Lion');
      expect(puzzle.category, PuzzleCategory.animals);
      expect(puzzle.imagePath, 'assets/images/animals/lion.png');
      expect(puzzle.difficulty.targetPieceCount, 4);
      expect(puzzle.grid.pieceCount, 4);
    });

    test('rejects empty id, name, or image path', () {
      expect(() => _puzzle(id: ''), throwsArgumentError);
      expect(() => _puzzle(name: ''), throwsArgumentError);
      expect(() => _puzzle(imagePath: ''), throwsArgumentError);
    });

    test('is equality-friendly by metadata', () {
      expect(_puzzle(), _puzzle());
      expect(_puzzle().hashCode, _puzzle().hashCode);
    });
  });
}

Puzzle _puzzle({
  String id = 'lion',
  String name = 'Lion',
  String imagePath = 'assets/images/animals/lion.png',
}) {
  return Puzzle(
    id: id,
    name: name,
    category: PuzzleCategory.animals,
    imagePath: imagePath,
    difficulty: PuzzleDifficulty.level(2),
    grid: GridSpec(rows: 2, columns: 2),
  );
}
