import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/puzzle_piece.dart';
import 'package:puzzle_kids/widgets/puzzle_piece_shape.dart';

void main() {
  group('PuzzlePieceShape', () {
    test('all-flat path stays inside tile bounds', () {
      const size = Size(86, 86);
      final path = const PuzzlePieceShape(
        PuzzlePieceEdges.allFlat,
      ).pathFor(size);

      expect(path.getBounds().left, greaterThanOrEqualTo(0));
      expect(path.getBounds().top, greaterThanOrEqualTo(0));
      expect(path.getBounds().right, lessThanOrEqualTo(size.width));
      expect(path.getBounds().bottom, lessThanOrEqualTo(size.height));
    });

    test('tabs and blanks never exceed crop/tile bounds', () {
      const size = Size(120, 96);
      const edges = PuzzlePieceEdges(
        top: PuzzlePieceEdge.tab,
        right: PuzzlePieceEdge.blank,
        bottom: PuzzlePieceEdge.blank,
        left: PuzzlePieceEdge.tab,
      );

      final path = const PuzzlePieceShape(edges).pathFor(size);
      final bounds = path.getBounds();

      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(bounds.bottom, lessThanOrEqualTo(size.height));
    });

    test('path generation is deterministic for the same edges and size', () {
      const size = Size(100, 100);
      const edges = PuzzlePieceEdges(
        top: PuzzlePieceEdge.blank,
        right: PuzzlePieceEdge.tab,
        bottom: PuzzlePieceEdge.tab,
        left: PuzzlePieceEdge.blank,
      );

      final first = const PuzzlePieceShape(edges).pathFor(size);
      final second = const PuzzlePieceShape(edges).pathFor(size);

      expect(first.getBounds(), second.getBounds());
      expect(first.computeMetrics().length, second.computeMetrics().length);
    });

    test('tabs protrude into expanded viewport from canonical cell', () {
      const size = Size(124, 124);
      const cellRect = Rect.fromLTWH(12, 12, 100, 100);
      const edges = PuzzlePieceEdges(
        top: PuzzlePieceEdge.tab,
        right: PuzzlePieceEdge.tab,
        bottom: PuzzlePieceEdge.tab,
        left: PuzzlePieceEdge.tab,
      );

      final bounds = const PuzzlePieceShape(
        edges,
      ).pathFor(size, cellRectInViewport: cellRect).getBounds();

      expect(bounds.left, lessThan(cellRect.left));
      expect(bounds.top, lessThan(cellRect.top));
      expect(bounds.right, greaterThan(cellRect.right));
      expect(bounds.bottom, greaterThan(cellRect.bottom));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(bounds.bottom, lessThanOrEqualTo(size.height));
    });

    test('exterior flats stay on board boundary in expanded viewport', () {
      const size = Size(112, 112);
      const cellRect = Rect.fromLTWH(0, 0, 100, 100);
      const edges = PuzzlePieceEdges(
        top: PuzzlePieceEdge.flat,
        right: PuzzlePieceEdge.tab,
        bottom: PuzzlePieceEdge.blank,
        left: PuzzlePieceEdge.flat,
      );

      final bounds = const PuzzlePieceShape(
        edges,
      ).pathFor(size, cellRectInViewport: cellRect).getBounds();

      expect(bounds.left, 0);
      expect(bounds.top, 0);
      expect(bounds.right, greaterThan(cellRect.right));
      expect(bounds.bottom, cellRect.bottom);
    });
  });
}
