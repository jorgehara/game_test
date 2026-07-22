import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_position.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/normalized_rect.dart';
import 'package:puzzle_kids/models/puzzle_piece.dart';
import 'package:puzzle_kids/widgets/puzzle_piece_geometry.dart';
import 'package:puzzle_kids/widgets/puzzle_piece_shape.dart';

void main() {
  group('PuzzlePieceGeometry.forBoard', () {
    test('1x1 keeps the canonical cell with no bleed', () {
      final geometry = PuzzlePieceGeometry.forBoard(
        piece: _piece(grid: GridSpec(rows: 1, columns: 1), row: 0, column: 0),
        boardSize: const Size(120, 80),
      );

      expect(geometry.visualRect, const Rect.fromLTWH(0, 0, 120, 80));
      expect(geometry.viewportSize, const Size(120, 80));
      expect(geometry.cellRectInViewport, const Rect.fromLTWH(0, 0, 120, 80));
      expect(geometry.sourceRect.left, 0);
      expect(geometry.sourceRect.top, 0);
      expect(geometry.sourceRect.right, 1);
      expect(geometry.sourceRect.bottom, 1);
      expect(geometry.bleed.left, 0);
      expect(geometry.bleed.top, 0);
      expect(geometry.bleed.right, 0);
      expect(geometry.bleed.bottom, 0);
      expect(geometry.hasLeftNeighbor, isFalse);
      expect(geometry.hasTopNeighbor, isFalse);
      expect(geometry.hasRightNeighbor, isFalse);
      expect(geometry.hasBottomNeighbor, isFalse);
    });

    test('2x2 top-left corner bleeds only toward interior neighbors', () {
      final geometry = PuzzlePieceGeometry.forBoard(
        piece: _piece(grid: GridSpec(rows: 2, columns: 2), row: 0, column: 0),
        boardSize: const Size(200, 200),
      );

      expect(geometry.bleed.left, 0);
      expect(geometry.bleed.top, 0);
      expect(geometry.bleed.right, 12);
      expect(geometry.bleed.bottom, 12);
      expect(geometry.visualRect, const Rect.fromLTWH(0, 0, 112, 112));
      expect(geometry.viewportSize, const Size(112, 112));
      expect(geometry.cellRectInViewport, const Rect.fromLTWH(0, 0, 100, 100));
      expect(geometry.sourceRect.left, 0);
      expect(geometry.sourceRect.top, 0);
      expect(geometry.sourceRect.right, closeTo(0.56, 0.0001));
      expect(geometry.sourceRect.bottom, closeTo(0.56, 0.0001));
      expect(geometry.hasLeftNeighbor, isFalse);
      expect(geometry.hasTopNeighbor, isFalse);
      expect(geometry.hasRightNeighbor, isTrue);
      expect(geometry.hasBottomNeighbor, isTrue);
    });

    test('3x3 center applies four-side bleed and bounded source rect', () {
      final geometry = PuzzlePieceGeometry.forBoard(
        piece: _piece(grid: GridSpec(rows: 3, columns: 3), row: 1, column: 1),
        boardSize: const Size(300, 240),
      );

      expect(geometry.bleed.left, 9.6);
      expect(geometry.bleed.top, 9.6);
      expect(geometry.bleed.right, 9.6);
      expect(geometry.bleed.bottom, 9.6);
      expect(geometry.visualRect.left, closeTo(90.4, 0.0001));
      expect(geometry.visualRect.top, closeTo(70.4, 0.0001));
      expect(geometry.visualRect.width, closeTo(119.2, 0.0001));
      expect(geometry.visualRect.height, closeTo(99.2, 0.0001));
      expect(geometry.cellRectInViewport.left, closeTo(9.6, 0.0001));
      expect(geometry.cellRectInViewport.top, closeTo(9.6, 0.0001));
      expect(geometry.cellRectInViewport.width, 100);
      expect(geometry.cellRectInViewport.height, 80);

      expect(geometry.sourceRect.left, closeTo(90.4 / 300, 0.0001));
      expect(geometry.sourceRect.top, closeTo(70.4 / 240, 0.0001));
      expect(geometry.sourceRect.right, closeTo(209.6 / 300, 0.0001));
      expect(geometry.sourceRect.bottom, closeTo(169.6 / 240, 0.0001));
      expect(_isNormalized(geometry.sourceRect), isTrue);
      expect(geometry.hasLeftNeighbor, isTrue);
      expect(geometry.hasTopNeighbor, isTrue);
      expect(geometry.hasRightNeighbor, isTrue);
      expect(geometry.hasBottomNeighbor, isTrue);
    });

    test('bottom-right corner source rect clamps to one', () {
      final geometry = PuzzlePieceGeometry.forBoard(
        piece: _piece(grid: GridSpec(rows: 2, columns: 2), row: 1, column: 1),
        boardSize: const Size(101, 99),
      );

      expect(geometry.bleed.left, closeTo(5.94, 0.0001));
      expect(geometry.bleed.top, closeTo(5.94, 0.0001));
      expect(geometry.bleed.right, 0);
      expect(geometry.bleed.bottom, 0);
      expect(geometry.sourceRect.right, 1);
      expect(geometry.sourceRect.bottom, 1);
      expect(_isNormalized(geometry.sourceRect), isTrue);
    });
  });

  group('PuzzlePieceGeometry path bounds', () {
    test('expanded center viewport can contain protruding tabs safely', () {
      final geometry = PuzzlePieceGeometry.forBoard(
        piece: _piece(
          grid: GridSpec(rows: 3, columns: 3),
          row: 1,
          column: 1,
          edges: const PuzzlePieceEdges(
            top: PuzzlePieceEdge.tab,
            right: PuzzlePieceEdge.tab,
            bottom: PuzzlePieceEdge.tab,
            left: PuzzlePieceEdge.tab,
          ),
        ),
        boardSize: const Size(300, 300),
      );

      final path = PuzzlePieceShape(
        geometry.piece.edges,
      ).pathFor(geometry.viewportSize);
      final bounds = path.getBounds();

      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(geometry.viewportSize.width));
      expect(bounds.bottom, lessThanOrEqualTo(geometry.viewportSize.height));
    });
  });
}

PuzzlePiece _piece({
  required GridSpec grid,
  required int row,
  required int column,
  PuzzlePieceEdges edges = PuzzlePieceEdges.allFlat,
}) {
  final position = GridPosition(row: row, column: column, grid: grid);
  return PuzzlePiece(
    id: 'piece-$row-$column',
    correctPosition: position,
    edges: edges,
    crop: NormalizedRect(
      left: column / grid.columns,
      top: row / grid.rows,
      width: 1 / grid.columns,
      height: 1 / grid.rows,
    ),
  );
}

bool _isNormalized(NormalizedRect rect) {
  return rect.left >= 0 && rect.top >= 0 && rect.right <= 1 && rect.bottom <= 1;
}
