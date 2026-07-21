import '../models/grid_position.dart';
import '../models/normalized_rect.dart';
import '../models/puzzle.dart';
import '../models/puzzle_piece.dart';

class PuzzlePieceGenerator {
  const PuzzlePieceGenerator._();

  static List<PuzzlePiece> generate(Puzzle puzzle) {
    final grid = puzzle.grid;
    if (!grid.isSupportedForGeneration) {
      throw ArgumentError.value(
        grid,
        'puzzle.grid',
        'Only 2x2 and 3x3 grids are supported for MVP generation',
      );
    }

    final pieces = <PuzzlePiece>[];
    for (var row = 0; row < grid.rows; row++) {
      for (var column = 0; column < grid.columns; column++) {
        final position = GridPosition(row: row, column: column, grid: grid);
        pieces.add(
          PuzzlePiece(
            id: '${puzzle.id}_${row}_$column',
            correctPosition: position,
            crop: NormalizedRect(
              left: column / grid.columns,
              top: row / grid.rows,
              width: 1 / grid.columns,
              height: 1 / grid.rows,
            ),
          ),
        );
      }
    }

    PuzzlePiece.validateList(pieces);
    return List.unmodifiable(pieces);
  }
}
