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
        'Only 1x1, 2x2 and 3x3 grids are supported for MVP generation',
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
            edges: _edgesFor(
              row: row,
              column: column,
              rows: grid.rows,
              columns: grid.columns,
            ),
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

  static PuzzlePieceEdges _edgesFor({
    required int row,
    required int column,
    required int rows,
    required int columns,
  }) {
    if (rows == 1 && columns == 1) {
      return PuzzlePieceEdges.allFlat;
    }

    return PuzzlePieceEdges(
      top: row == 0
          ? PuzzlePieceEdge.flat
          : _innerEdge(row - 1, column, 1).complement,
      right: column == columns - 1
          ? PuzzlePieceEdge.flat
          : _innerEdge(row, column, 0),
      bottom: row == rows - 1
          ? PuzzlePieceEdge.flat
          : _innerEdge(row, column, 1),
      left: column == 0
          ? PuzzlePieceEdge.flat
          : _innerEdge(row, column - 1, 0).complement,
    );
  }

  static PuzzlePieceEdge _innerEdge(int row, int column, int axis) {
    return (row + column + axis).isEven
        ? PuzzlePieceEdge.tab
        : PuzzlePieceEdge.blank;
  }
}
