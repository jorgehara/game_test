import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';

@immutable
class PuzzlePieceShape {
  const PuzzlePieceShape(this.edges);

  final PuzzlePieceEdges edges;

  static const _cornerRadiusFactor = 0.10;
  static const _safeInsetFactor = 0.12;
  static const _tabStart = 0.34;
  static const _tabEnd = 0.66;
  static const _tabMid = 0.50;

  Path pathFor(Size size, {Rect? cellRectInViewport}) {
    final viewport = Offset.zero & size;
    final rect = cellRectInViewport ?? viewport;
    if (viewport.isEmpty || rect.isEmpty) return Path();

    if (edges == PuzzlePieceEdges.allFlat) {
      final radius = Radius.circular(rect.shortestSide * _cornerRadiusFactor);
      return Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
    }

    final depth = rect.shortestSide * _safeInsetFactor;
    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;

    return Path()
      ..moveTo(left, top)
      .._addHorizontalEdge(
        start: Offset(left, top),
        end: Offset(right, top),
        edge: edges.top,
        outward: -1,
        minOutward: viewport.top,
        maxInward: bottom,
        depth: depth,
      )
      .._addVerticalEdge(
        start: Offset(right, top),
        end: Offset(right, bottom),
        edge: edges.right,
        outward: 1,
        minOutward: viewport.right,
        maxInward: left,
        depth: depth,
      )
      .._addHorizontalEdge(
        start: Offset(right, bottom),
        end: Offset(left, bottom),
        edge: edges.bottom,
        outward: 1,
        minOutward: viewport.bottom,
        maxInward: top,
        depth: depth,
      )
      .._addVerticalEdge(
        start: Offset(left, bottom),
        end: Offset(left, top),
        edge: edges.left,
        outward: -1,
        minOutward: viewport.left,
        maxInward: right,
        depth: depth,
      )
      ..close();
  }
}

class PuzzlePieceShapeClipper extends CustomClipper<Path> {
  const PuzzlePieceShapeClipper({required this.edges, this.cellRectInViewport});

  final PuzzlePieceEdges edges;
  final Rect? cellRectInViewport;

  @override
  Path getClip(Size size) => PuzzlePieceShape(
    edges,
  ).pathFor(size, cellRectInViewport: cellRectInViewport);

  @override
  bool shouldReclip(PuzzlePieceShapeClipper oldClipper) {
    return oldClipper.edges != edges ||
        oldClipper.cellRectInViewport != cellRectInViewport;
  }
}

class PuzzlePieceShapePainter extends CustomPainter {
  const PuzzlePieceShapePainter({
    required this.edges,
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 2,
    this.shadowColor = Colors.transparent,
    this.shadowBlurRadius = 0,
    this.shadowOffset = Offset.zero,
    this.paintFill = true,
    this.paintBorder = true,
    this.cellRectInViewport,
  });

  final PuzzlePieceEdges edges;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final bool paintFill;
  final bool paintBorder;
  final Rect? cellRectInViewport;

  @override
  void paint(Canvas canvas, Size size) {
    final path = PuzzlePieceShape(
      edges,
    ).pathFor(size, cellRectInViewport: cellRectInViewport);
    if (path.getBounds().isEmpty) return;

    if (shadowColor.a > 0 && shadowBlurRadius > 0) {
      canvas.drawShadow(
        path.shift(shadowOffset),
        shadowColor,
        shadowBlurRadius,
        true,
      );
    }

    if (paintFill) {
      canvas.drawPath(path, Paint()..color = fillColor);
    }

    if (paintBorder && borderWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(PuzzlePieceShapePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.shadowBlurRadius != shadowBlurRadius ||
        oldDelegate.shadowOffset != shadowOffset ||
        oldDelegate.paintFill != paintFill ||
        oldDelegate.paintBorder != paintBorder ||
        oldDelegate.cellRectInViewport != cellRectInViewport;
  }
}

extension on Path {
  void _addHorizontalEdge({
    required Offset start,
    required Offset end,
    required PuzzlePieceEdge edge,
    required double outward,
    required double minOutward,
    required double maxInward,
    required double depth,
  }) {
    final length = end.dx - start.dx;
    final y = start.dy;
    if (edge == PuzzlePieceEdge.flat) {
      lineTo(end.dx, end.dy);
      return;
    }

    final x1 = start.dx + length * PuzzlePieceShape._tabStart;
    final xm = start.dx + length * PuzzlePieceShape._tabMid;
    final x2 = start.dx + length * PuzzlePieceShape._tabEnd;
    final targetY = edge == PuzzlePieceEdge.tab
        ? _clampAxis(y + depth * outward, minOutward, maxInward)
        : _clampAxis(y - depth * outward, minOutward, maxInward);

    lineTo(x1, y);
    cubicTo(x1, y, x1, targetY, xm, targetY);
    cubicTo(x2, targetY, x2, y, x2, y);
    lineTo(end.dx, end.dy);
  }

  void _addVerticalEdge({
    required Offset start,
    required Offset end,
    required PuzzlePieceEdge edge,
    required double outward,
    required double minOutward,
    required double maxInward,
    required double depth,
  }) {
    final length = end.dy - start.dy;
    final x = start.dx;
    if (edge == PuzzlePieceEdge.flat) {
      lineTo(end.dx, end.dy);
      return;
    }

    final y1 = start.dy + length * PuzzlePieceShape._tabStart;
    final ym = start.dy + length * PuzzlePieceShape._tabMid;
    final y2 = start.dy + length * PuzzlePieceShape._tabEnd;
    final targetX = edge == PuzzlePieceEdge.tab
        ? _clampAxis(x + depth * outward, minOutward, maxInward)
        : _clampAxis(x - depth * outward, minOutward, maxInward);

    lineTo(x, y1);
    cubicTo(x, y1, targetX, y1, targetX, ym);
    cubicTo(targetX, y2, x, y2, x, y2);
    lineTo(end.dx, end.dy);
  }

  double _clampAxis(double value, double a, double b) {
    final min = a < b ? a : b;
    final max = a < b ? b : a;
    return value.clamp(min, max).toDouble();
  }
}
