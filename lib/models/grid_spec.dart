class GridSpec {
  GridSpec({required int rows, required int columns})
    : rows = _validatePositive(rows, 'rows'),
      columns = _validatePositive(columns, 'columns');

  final int rows;
  final int columns;

  int get pieceCount => rows * columns;

  bool get isSupportedForGeneration {
    return (rows == 1 && columns == 1) ||
        (rows == 2 && columns == 2) ||
        (rows == 3 && columns == 3);
  }

  static int _validatePositive(int value, String name) {
    if (value < 1) {
      throw ArgumentError.value(value, name, 'Must be positive');
    }

    return value;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GridSpec && other.rows == rows && other.columns == columns;
  }

  @override
  int get hashCode => Object.hash(rows, columns);

  @override
  String toString() => 'GridSpec(rows: $rows, columns: $columns)';
}
