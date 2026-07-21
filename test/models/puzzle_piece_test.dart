import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_position.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/normalized_rect.dart';
import 'package:puzzle_kids/models/puzzle_piece.dart';

void main() {
  group('PuzzlePiece', () {
    final grid = GridSpec(rows: 2, columns: 2);
    final correctPosition = GridPosition(row: 1, column: 0, grid: grid);

    test(
      'keeps stable identity, correct position, current position, crop, and index',
      () {
        final piece = PuzzlePiece(
          id: 'lion_1_0',
          correctPosition: correctPosition,
          currentPosition: GridPosition(row: 0, column: 1, grid: grid),
          crop: NormalizedRect(left: 0, top: 0.5, width: 0.5, height: 0.5),
        );

        expect(piece.id, 'lion_1_0');
        expect(piece.correctIndex, 2);
        expect(piece.correctPosition, correctPosition);
        expect(
          piece.currentPosition,
          GridPosition(row: 0, column: 1, grid: grid),
        );
        expect(piece.crop.top, 0.5);
      },
    );

    test('rejects empty ids', () {
      expect(
        () => PuzzlePiece(
          id: '',
          correctPosition: correctPosition,
          crop: NormalizedRect(left: 0, top: 0, width: 0.5, height: 0.5),
        ),
        throwsArgumentError,
      );
    });

    test('rejects current positions from a different grid', () {
      expect(
        () => PuzzlePiece(
          id: 'lion_1_0',
          correctPosition: correctPosition,
          currentPosition: GridPosition(
            row: 0,
            column: 0,
            grid: GridSpec(rows: 3, columns: 3),
          ),
          crop: NormalizedRect(left: 0, top: 0.5, width: 0.5, height: 0.5),
        ),
        throwsArgumentError,
      );
    });

    test(
      'validates duplicate ids and duplicate correct positions in lists',
      () {
        final first = _piece(id: 'lion_0_0', row: 0, column: 0, grid: grid);
        final sameId = _piece(id: 'lion_0_0', row: 0, column: 1, grid: grid);
        final samePosition = _piece(
          id: 'lion_duplicate',
          row: 0,
          column: 0,
          grid: grid,
        );

        expect(
          () => PuzzlePiece.validateList([first, sameId]),
          throwsArgumentError,
        );
        expect(
          () => PuzzlePiece.validateList([first, samePosition]),
          throwsArgumentError,
        );
      },
    );

    test('is equality-friendly by value', () {
      expect(
        _piece(id: 'lion_0_0', row: 0, column: 0, grid: grid),
        _piece(id: 'lion_0_0', row: 0, column: 0, grid: grid),
      );
    });
  });
}

PuzzlePiece _piece({
  required String id,
  required int row,
  required int column,
  required GridSpec grid,
}) {
  return PuzzlePiece(
    id: id,
    correctPosition: GridPosition(row: row, column: column, grid: grid),
    crop: NormalizedRect(
      left: column / grid.columns,
      top: row / grid.rows,
      width: 1 / grid.columns,
      height: 1 / grid.rows,
    ),
  );
}
