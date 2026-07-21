import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_position.dart';
import 'package:puzzle_kids/models/grid_spec.dart';

void main() {
  group('GridPosition', () {
    final grid = GridSpec(rows: 2, columns: 3);

    test('accepts zero-based coordinates inside grid bounds', () {
      final position = GridPosition(row: 1, column: 2, grid: grid);

      expect(position.row, 1);
      expect(position.column, 2);
      expect(position.index, 5);
    });

    test('rejects negative coordinates', () {
      expect(
        () => GridPosition(row: -1, column: 0, grid: grid),
        throwsArgumentError,
      );
      expect(
        () => GridPosition(row: 0, column: -1, grid: grid),
        throwsArgumentError,
      );
    });

    test('rejects coordinates outside grid bounds', () {
      expect(
        () => GridPosition(row: 2, column: 0, grid: grid),
        throwsArgumentError,
      );
      expect(
        () => GridPosition(row: 0, column: 3, grid: grid),
        throwsArgumentError,
      );
    });

    test('is equality-friendly by coordinates and grid', () {
      expect(
        GridPosition(row: 1, column: 2, grid: grid),
        GridPosition(row: 1, column: 2, grid: grid),
      );
    });
  });
}
