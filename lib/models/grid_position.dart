import 'grid_spec.dart';

class GridPosition {
  GridPosition({required int row, required int column, required GridSpec grid})
    : row = _validateRow(row, grid),
      column = _validateColumn(column, grid),
      grid = grid;

  final int row;
  final int column;
  final GridSpec grid;

  int get index => row * grid.columns + column;

  static int _validateRow(int row, GridSpec grid) {
    if (row < 0 || row >= grid.rows) {
      throw ArgumentError.value(row, 'row', 'Must be within grid rows');
    }

    return row;
  }

  static int _validateColumn(int column, GridSpec grid) {
    if (column < 0 || column >= grid.columns) {
      throw ArgumentError.value(
        column,
        'column',
        'Must be within grid columns',
      );
    }

    return column;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GridPosition &&
            other.row == row &&
            other.column == column &&
            other.grid == grid;
  }

  @override
  int get hashCode => Object.hash(row, column, grid);

  @override
  String toString() => 'GridPosition(row: $row, column: $column, grid: $grid)';
}
