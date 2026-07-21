import '../models/grid_spec.dart';
import '../models/puzzle.dart';
import '../models/puzzle_category.dart';
import '../models/puzzle_difficulty.dart';

class PuzzleCatalogService {
  PuzzleCatalogService._();

  static final List<Puzzle> _puzzles = List.unmodifiable([
    _puzzle(
      id: 'lion',
      name: 'Lion',
      category: PuzzleCategory.animals,
      level: 2,
      grid: GridSpec(rows: 2, columns: 2),
    ),
    _puzzle(
      id: 'elephant',
      name: 'Elephant',
      category: PuzzleCategory.animals,
      level: 4,
      grid: GridSpec(rows: 3, columns: 3),
    ),
    _puzzle(
      id: 'giraffe',
      name: 'Giraffe',
      category: PuzzleCategory.animals,
      level: 1,
      grid: GridSpec(rows: 1, columns: 2),
    ),
    _puzzle(
      id: 'panda',
      name: 'Panda',
      category: PuzzleCategory.animals,
      level: 5,
      grid: GridSpec(rows: 3, columns: 4),
    ),
    _puzzle(
      id: 'car',
      name: 'Car',
      category: PuzzleCategory.vehicles,
      level: 2,
      grid: GridSpec(rows: 2, columns: 2),
    ),
    _puzzle(
      id: 'train',
      name: 'Train',
      category: PuzzleCategory.vehicles,
      level: 3,
      grid: GridSpec(rows: 2, columns: 3),
    ),
    _puzzle(
      id: 'airplane',
      name: 'Airplane',
      category: PuzzleCategory.vehicles,
      level: 4,
      grid: GridSpec(rows: 3, columns: 3),
    ),
    _puzzle(
      id: 'boat',
      name: 'Boat',
      category: PuzzleCategory.vehicles,
      level: 1,
      grid: GridSpec(rows: 1, columns: 2),
    ),
    _puzzle(
      id: 'apple',
      name: 'Apple',
      category: PuzzleCategory.fruits,
      level: 1,
      grid: GridSpec(rows: 1, columns: 2),
    ),
    _puzzle(
      id: 'banana',
      name: 'Banana',
      category: PuzzleCategory.fruits,
      level: 2,
      grid: GridSpec(rows: 2, columns: 2),
    ),
    _puzzle(
      id: 'strawberry',
      name: 'Strawberry',
      category: PuzzleCategory.fruits,
      level: 3,
      grid: GridSpec(rows: 2, columns: 3),
    ),
    _puzzle(
      id: 'cow',
      name: 'Cow',
      category: PuzzleCategory.farm,
      level: 2,
      grid: GridSpec(rows: 2, columns: 2),
    ),
    _puzzle(
      id: 'tractor',
      name: 'Tractor',
      category: PuzzleCategory.farm,
      level: 3,
      grid: GridSpec(rows: 2, columns: 3),
    ),
    _puzzle(
      id: 'barn',
      name: 'Barn',
      category: PuzzleCategory.farm,
      level: 5,
      grid: GridSpec(rows: 3, columns: 4),
    ),
    _puzzle(
      id: 'trex',
      name: 'T-Rex',
      category: PuzzleCategory.dinosaurs,
      level: 4,
      grid: GridSpec(rows: 3, columns: 3),
    ),
    _puzzle(
      id: 'triceratops',
      name: 'Triceratops',
      category: PuzzleCategory.dinosaurs,
      level: 5,
      grid: GridSpec(rows: 3, columns: 4),
    ),
    _puzzle(
      id: 'stegosaurus',
      name: 'Stegosaurus',
      category: PuzzleCategory.dinosaurs,
      level: 3,
      grid: GridSpec(rows: 2, columns: 3),
    ),
    _puzzle(
      id: 'rocket',
      name: 'Rocket',
      category: PuzzleCategory.space,
      level: 4,
      grid: GridSpec(rows: 3, columns: 3),
    ),
    _puzzle(
      id: 'planet',
      name: 'Planet',
      category: PuzzleCategory.space,
      level: 1,
      grid: GridSpec(rows: 1, columns: 2),
    ),
    _puzzle(
      id: 'astronaut',
      name: 'Astronaut',
      category: PuzzleCategory.space,
      level: 5,
      grid: GridSpec(rows: 3, columns: 4),
    ),
  ]);

  static List<Puzzle> all() {
    validate(_puzzles);
    return _puzzles;
  }

  static void validate(Iterable<Puzzle> puzzles) {
    final ids = <String>{};

    for (final puzzle in puzzles) {
      if (!ids.add(puzzle.id)) {
        throw ArgumentError.value(puzzle.id, 'puzzles', 'Duplicate puzzle id');
      }

      final expectedPrefix = 'assets/images/${puzzle.category.id}/';
      if (!puzzle.imagePath.startsWith(expectedPrefix) ||
          !puzzle.imagePath.endsWith('.png')) {
        throw ArgumentError.value(
          puzzle.imagePath,
          'puzzles',
          'Image path must be inert category metadata under assets/images',
        );
      }

      if (puzzle.grid.pieceCount != puzzle.difficulty.targetPieceCount) {
        throw ArgumentError.value(
          puzzle.grid,
          'puzzles',
          'Grid piece count must match difficulty target piece count',
        );
      }
    }
  }

  static Puzzle _puzzle({
    required String id,
    required String name,
    required PuzzleCategory category,
    required int level,
    required GridSpec grid,
  }) {
    return Puzzle(
      id: id,
      name: name,
      category: category,
      imagePath: 'assets/images/${category.id}/$id.png',
      difficulty: PuzzleDifficulty.level(level),
      grid: grid,
    );
  }
}
