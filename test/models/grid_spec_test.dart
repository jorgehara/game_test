import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_spec.dart';

void main() {
  group('GridSpec', () {
    test('models rectangular grids and calculates piece count', () {
      final grid = GridSpec(rows: 2, columns: 3);

      expect(grid.rows, 2);
      expect(grid.columns, 3);
      expect(grid.pieceCount, 6);
    });

    test('marks only 1x1, 2x2, and 3x3 as generation-supported', () {
      expect(GridSpec(rows: 1, columns: 1).isSupportedForGeneration, isTrue);
      expect(GridSpec(rows: 2, columns: 2).isSupportedForGeneration, isTrue);
      expect(GridSpec(rows: 3, columns: 3).isSupportedForGeneration, isTrue);
      expect(GridSpec(rows: 2, columns: 3).isSupportedForGeneration, isFalse);
    });

    test('rejects non-positive rows or columns', () {
      expect(() => GridSpec(rows: 0, columns: 2), throwsArgumentError);
      expect(() => GridSpec(rows: 2, columns: 0), throwsArgumentError);
      expect(() => GridSpec(rows: -1, columns: 2), throwsArgumentError);
      expect(() => GridSpec(rows: 2, columns: -1), throwsArgumentError);
    });

    test('is equality-friendly by dimensions', () {
      expect(GridSpec(rows: 3, columns: 3), GridSpec(rows: 3, columns: 3));
      expect(
        GridSpec(rows: 3, columns: 3).hashCode,
        GridSpec(rows: 3, columns: 3).hashCode,
      );
    });
  });
}
