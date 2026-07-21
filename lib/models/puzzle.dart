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
    String? thumbnailPath,
    this.placeholderSeed = 0,
    String? placeholderLabel,
  }) : id = _validateNotEmpty(id, 'id'),
       name = _validateNotEmpty(name, 'name'),
       imagePath = _validateNotEmpty(imagePath, 'imagePath'),
       thumbnailPath = _validateNotEmpty(
         thumbnailPath ?? imagePath.replaceFirst('.png', '_thumb.png'),
         'thumbnailPath',
       ),
       placeholderLabel = _validateNotEmpty(
         placeholderLabel ?? name,
         'placeholderLabel',
       );

  final String id;
  final String name;
  final PuzzleCategory category;
  final String imagePath;
  final String thumbnailPath;
  final PuzzleDifficulty difficulty;
  final GridSpec grid;
  final int placeholderSeed;
  final String placeholderLabel;

  String get levelLabel => 'Nivel ${difficulty.level}';

  String get progressLabel => '0/${grid.pieceCount} piezas';

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
            other.thumbnailPath == thumbnailPath &&
            other.difficulty == difficulty &&
            other.grid == grid &&
            other.placeholderSeed == placeholderSeed &&
            other.placeholderLabel == placeholderLabel;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    imagePath,
    thumbnailPath,
    difficulty,
    grid,
    placeholderSeed,
    placeholderLabel,
  );

  @override
  String toString() {
    return 'Puzzle(id: $id, name: $name, category: $category, imagePath: $imagePath, thumbnailPath: $thumbnailPath, difficulty: $difficulty, grid: $grid)';
  }
}
