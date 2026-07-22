import '../models/grid_spec.dart';
import '../models/puzzle.dart';
import '../models/puzzle_category.dart';
import '../models/puzzle_difficulty.dart';
import 'asset_manifest_validator.dart';

class PuzzleCatalogService {
  PuzzleCatalogService._();

  static final List<Puzzle> _puzzles = List.unmodifiable([
    _puzzle(id: 'lion', name: 'Lion', category: PuzzleCategory.animals),
    _puzzle(
      id: 'elephant',
      name: 'Elephant',
      category: PuzzleCategory.animals,
      level: 4,
    ),
    _puzzle(id: 'fox', name: 'Fox', category: PuzzleCategory.animals),
    _puzzle(id: 'car', name: 'Car', category: PuzzleCategory.vehicles),
    _puzzle(
      id: 'airplane',
      name: 'Airplane',
      category: PuzzleCategory.vehicles,
      level: 4,
    ),
    _puzzle(id: 'bus', name: 'Bus', category: PuzzleCategory.vehicles),
    _puzzle(id: 'banana', name: 'Banana', category: PuzzleCategory.fruits),
    _puzzle(
      id: 'strawberry',
      name: 'Strawberry',
      category: PuzzleCategory.fruits,
      level: 4,
    ),
    _puzzle(id: 'pear', name: 'Pear', category: PuzzleCategory.fruits),
    _puzzle(id: 'cow', name: 'Cow', category: PuzzleCategory.farm),
    _puzzle(id: 'barn', name: 'Barn', category: PuzzleCategory.farm, level: 4),
    _puzzle(id: 'chick', name: 'Chick', category: PuzzleCategory.farm),
    _puzzle(
      id: 'trex',
      name: 'T-Rex',
      category: PuzzleCategory.dinosaurs,
      level: 4,
    ),
    _puzzle(
      id: 'stegosaurus',
      name: 'Stegosaurus',
      category: PuzzleCategory.dinosaurs,
    ),
    _puzzle(
      id: 'rocket',
      name: 'Rocket',
      category: PuzzleCategory.space,
      level: 4,
    ),
    _puzzle(id: 'planet', name: 'Planet', category: PuzzleCategory.space),
    _puzzle(
      id: 'castle-bright',
      name: 'Castillo brillante',
      category: PuzzleCategory.castles,
      placeholderLabel: 'Castillo con torres redondas',
    ),
    _puzzle(
      id: 'castillo-princesa',
      name: 'Castillo princesa',
      category: PuzzleCategory.castles,
      placeholderLabel: 'Castillo de princesa con torres suaves',
      imageExtension: 'webp',
    ),
    _puzzle(
      id: 'castle-rainbow',
      name: 'Castillo arcoíris',
      category: PuzzleCategory.castles,
      level: 4,
      placeholderLabel: 'Castillo con puente seguro',
    ),
    _puzzle(
      id: 'princess-crown',
      name: 'Corona de princesa',
      category: PuzzleCategory.princesses,
      placeholderLabel: 'Corona amable de princesa',
    ),
    _puzzle(
      id: 'princess-garden',
      name: 'Jardín de princesa',
      category: PuzzleCategory.princesses,
      level: 4,
      placeholderLabel: 'Jardín mágico con flores',
    ),
    _puzzle(
      id: 'unicorn-cloud',
      name: 'Unicornio nube',
      category: PuzzleCategory.unicorns,
      placeholderLabel: 'Unicornio sobre una nube',
    ),
    _puzzle(
      id: 'unicorn-stars',
      name: 'Unicornio estrellas',
      category: PuzzleCategory.unicorns,
      level: 4,
      placeholderLabel: 'Unicornio con estrellas',
    ),
    _puzzle(
      id: 'dragon-kite',
      name: 'Dragón barrilete',
      category: PuzzleCategory.dinosaurs,
      level: 4,
      placeholderLabel: 'Dragón bebé con barrilete',
    ),
    _puzzle(
      id: 'mermaid-lagoon',
      name: 'Laguna sirena',
      category: PuzzleCategory.ocean,
      placeholderLabel: 'Sirena entre olas suaves',
    ),
    _puzzle(
      id: 'rocket-moon',
      name: 'Cohete lunar',
      category: PuzzleCategory.space,
      level: 4,
      placeholderLabel: 'Cohete feliz rumbo a la luna',
    ),
    _puzzle(
      id: 'fox-forest',
      name: 'Zorro del bosque',
      category: PuzzleCategory.animals,
      placeholderLabel: 'Zorro naranja entre hojas',
    ),
    _puzzle(
      id: 'rainbow-bus',
      name: 'Colectivo arcoíris',
      category: PuzzleCategory.vehicles,
      placeholderLabel: 'Colectivo escolar de colores',
    ),
    _puzzle(
      id: 'berry-cupcake',
      name: 'Cupcake de frutillas',
      category: PuzzleCategory.fruits,
      placeholderLabel: 'Cupcake frutal con sonrisa',
    ),
    _puzzle(id: 'whale', name: 'Ballena', category: PuzzleCategory.ocean),
    _puzzle(
      id: 'turtle',
      name: 'Tortuga',
      category: PuzzleCategory.ocean,
      level: 4,
    ),
    _puzzle(
      id: 'atlas-dinosaurs',
      name: 'Dinosaurios aventureros',
      category: PuzzleCategory.dinosaurs,
      level: 4,
      imageExtension: 'webp',
    ),
    _puzzle(
      id: 'atlas-race-car',
      name: 'Auto de carrera',
      category: PuzzleCategory.vehicles,
      level: 4,
      imageExtension: 'webp',
    ),
    _puzzle(
      id: 'atlas-princess-castle',
      name: 'Princesa y castillo',
      category: PuzzleCategory.castles,
      imageExtension: 'webp',
    ),
    _puzzle(
      id: 'atlas-doctor',
      name: 'Médica amable',
      category: PuzzleCategory.professions,
      imageExtension: 'webp',
    ),
    _puzzle(
      id: 'atlas-astronaut',
      name: 'Astronauta espacial',
      category: PuzzleCategory.space,
      level: 4,
      imageExtension: 'webp',
    ),
    _puzzle(
      id: 'atlas-animals',
      name: 'Animales amigos',
      category: PuzzleCategory.animals,
      imageExtension: 'webp',
    ),
    _puzzle(
      id: 'atlas-airplane',
      name: 'Avión alegre',
      category: PuzzleCategory.vehicles,
      imageExtension: 'webp',
    ),
    _puzzle(
      id: 'atlas-truck',
      name: 'Camión de trabajo',
      category: PuzzleCategory.vehicles,
      imageExtension: 'webp',
    ),
    _puzzle(
      id: 'atlas-emergency-vehicles',
      name: 'Vehículos de emergencia',
      category: PuzzleCategory.vehicles,
      level: 4,
      imageExtension: 'webp',
    ),
  ]);

  static List<Puzzle> all() {
    validate(_puzzles);
    return _puzzles;
  }

  static List<Puzzle> playable() {
    return List.unmodifiable(
      all().where((puzzle) => puzzle.grid.isSupportedForGeneration),
    );
  }

  static List<Puzzle> playableByCategory(PuzzleCategory category) {
    return List.unmodifiable(
      playable().where((puzzle) => puzzle.category == category),
    );
  }

  static AssetManifestEntry? approvedAssetFor(
    Puzzle puzzle,
    Iterable<AssetManifestEntry> manifest, {
    Set<String> existingAssetPaths = const {},
  }) {
    if (!_supportsRenderedImageGrid(puzzle.grid)) {
      return null;
    }

    final usableAssets = AssetManifestValidator.approvedUsableAssets(
      manifest.where((entry) => entry.id == puzzle.id),
      existingAssetPaths: existingAssetPaths,
    );

    return usableAssets.isEmpty ? null : usableAssets.first;
  }

  static bool _supportsRenderedImageGrid(GridSpec grid) {
    return grid.rows == grid.columns &&
        (grid.rows == 1 || grid.rows == 2 || grid.rows == 3);
  }

  static void validate(Iterable<Puzzle> puzzles) {
    final ids = <String>{};

    for (final puzzle in puzzles) {
      if (!ids.add(puzzle.id)) {
        throw ArgumentError.value(puzzle.id, 'puzzles', 'Duplicate puzzle id');
      }

      _validateInertPath(puzzle, puzzle.imagePath, 'imagePath');
      _validateInertPath(puzzle, puzzle.thumbnailPath, 'thumbnailPath');

      if (!puzzle.grid.isSupportedForGeneration) {
        throw ArgumentError.value(
          puzzle.grid,
          'puzzles',
          'Playable catalog supports only 2x2 and 3x3 grids',
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

  static void _validateInertPath(Puzzle puzzle, String path, String fieldName) {
    final expectedPrefix = 'assets/images/${puzzle.category.id}/';
    final allowedExtension = path.endsWith('.png') || path.endsWith('.webp');
    if (!path.startsWith(expectedPrefix) || !allowedExtension) {
      throw ArgumentError.value(
        path,
        fieldName,
        'Image path must be inert PNG/WebP category metadata under assets/images',
      );
    }
  }

  static Puzzle _puzzle({
    required String id,
    required String name,
    required PuzzleCategory category,
    int level = 2,
    String? placeholderLabel,
    String imageExtension = 'png',
  }) {
    final grid = level == 4
        ? GridSpec(rows: 3, columns: 3)
        : GridSpec(rows: 2, columns: 2);

    return Puzzle(
      id: id,
      name: name,
      category: category,
      imagePath: 'assets/images/${category.id}/$id.$imageExtension',
      thumbnailPath: 'assets/images/${category.id}/${id}_thumb.$imageExtension',
      difficulty: PuzzleDifficulty.level(level),
      grid: grid,
      placeholderSeed: id.hashCode,
      placeholderLabel: placeholderLabel ?? name,
    );
  }
}
