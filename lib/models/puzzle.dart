import 'grid_spec.dart';
import 'puzzle_category.dart';
import 'puzzle_difficulty.dart';

class Puzzle {
  Puzzle({
    required String id,
    required String name,
    required this.category,
    required String imagePath,
    required this.difficulty,
    required this.grid,
  }) : id = _validateNotEmpty(id, 'id'),
       name = _validateNotEmpty(name, 'name'),
       imagePath = _validateNotEmpty(imagePath, 'imagePath');

  final String id;
  final String name;
  final PuzzleCategory category;
  final String imagePath;
  final PuzzleDifficulty difficulty;
  final GridSpec grid;

  static String _validateNotEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Must not be empty');
    }

    return value;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Puzzle &&
            other.id == id &&
            other.name == name &&
            other.category == category &&
            other.imagePath == imagePath &&
            other.difficulty == difficulty &&
            other.grid == grid;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, category, imagePath, difficulty, grid);

  @override
  String toString() {
    return 'Puzzle(id: $id, name: $name, category: $category, imagePath: $imagePath, difficulty: $difficulty, grid: $grid)';
  }
}
