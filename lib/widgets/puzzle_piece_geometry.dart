import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/normalized_rect.dart';
import '../models/puzzle_piece.dart';

/// Deterministic render geometry for one puzzle piece.
///
/// The canonical cell stays the source of truth for placement. Board rendering
/// may expand the visual viewport into existing neighbor cells so tabs/blanks
/// can interlock, but exterior board sides never bleed outside the board.
@immutable
class PuzzlePieceGeometry {
  const PuzzlePieceGeometry._({
    required this.piece,
    required this.visualRect,
    required this.viewportSize,
    required this.cellRectInViewport,
    required this.sourceRect,
    required this.bleed,
    required this.hasLeftNeighbor,
    required this.hasTopNeighbor,
    required this.hasRightNeighbor,
    required this.hasBottomNeighbor,
    required this.paintInternalOutline,
  });

  static const double bleedFactor = 0.12;
  static const double defaultPresentationSize = 86;

  final PuzzlePiece piece;
  final Rect visualRect;
  final Size viewportSize;
  final Rect cellRectInViewport;
  final NormalizedRect sourceRect;
  final EdgeInsets bleed;
  final bool hasLeftNeighbor;
  final bool hasTopNeighbor;
  final bool hasRightNeighbor;
  final bool hasBottomNeighbor;
  final bool paintInternalOutline;

  /// Board geometry expands only toward existing neighbors.
  factory PuzzlePieceGeometry.forBoard({
    required PuzzlePiece piece,
    required Size boardSize,
  }) {
    _validateSize(boardSize, 'boardSize');

    final position = piece.correctPosition;
    final grid = position.grid;
    final cellWidth = boardSize.width / grid.columns;
    final cellHeight = boardSize.height / grid.rows;
    final baseBleed = math.min(cellWidth, cellHeight) * bleedFactor;

    final hasLeftNeighbor = position.column > 0;
    final hasTopNeighbor = position.row > 0;
    final hasRightNeighbor = position.column < grid.columns - 1;
    final hasBottomNeighbor = position.row < grid.rows - 1;

    final bleed = EdgeInsets.only(
      left: hasLeftNeighbor ? baseBleed : 0,
      top: hasTopNeighbor ? baseBleed : 0,
      right: hasRightNeighbor ? baseBleed : 0,
      bottom: hasBottomNeighbor ? baseBleed : 0,
    );

    final cellRect = Rect.fromLTWH(
      position.column * cellWidth,
      position.row * cellHeight,
      cellWidth,
      cellHeight,
    );
    final visualRect = Rect.fromLTRB(
      cellRect.left - bleed.left,
      cellRect.top - bleed.top,
      cellRect.right + bleed.right,
      cellRect.bottom + bleed.bottom,
    );

    return PuzzlePieceGeometry._(
      piece: piece,
      visualRect: visualRect,
      viewportSize: visualRect.size,
      cellRectInViewport: Rect.fromLTWH(
        bleed.left,
        bleed.top,
        cellWidth,
        cellHeight,
      ),
      sourceRect: _sourceRectFor(visualRect, boardSize),
      bleed: bleed,
      hasLeftNeighbor: hasLeftNeighbor,
      hasTopNeighbor: hasTopNeighbor,
      hasRightNeighbor: hasRightNeighbor,
      hasBottomNeighbor: hasBottomNeighbor,
      paintInternalOutline: false,
    );
  }

  /// Tray geometry keeps a bounded presentation viewport and the piece's
  /// original crop. PR1b wires board/tray/drag call sites to this contract.
  factory PuzzlePieceGeometry.forTray({
    required PuzzlePiece piece,
    Size size = const Size.square(defaultPresentationSize),
  }) {
    return PuzzlePieceGeometry._presentation(piece: piece, size: size);
  }

  /// Drag geometry shares tray semantics unless a larger preview size is passed.
  factory PuzzlePieceGeometry.forDrag({
    required PuzzlePiece piece,
    Size size = const Size.square(defaultPresentationSize),
  }) {
    return PuzzlePieceGeometry._presentation(piece: piece, size: size);
  }

  factory PuzzlePieceGeometry._presentation({
    required PuzzlePiece piece,
    required Size size,
  }) {
    _validateSize(size, 'size');

    final rect = Offset.zero & size;
    return PuzzlePieceGeometry._(
      piece: piece,
      visualRect: rect,
      viewportSize: size,
      cellRectInViewport: rect,
      sourceRect: piece.crop,
      bleed: EdgeInsets.zero,
      hasLeftNeighbor: false,
      hasTopNeighbor: false,
      hasRightNeighbor: false,
      hasBottomNeighbor: false,
      paintInternalOutline: true,
    );
  }

  static NormalizedRect _sourceRectFor(Rect visualRect, Size boardSize) {
    final left = _clamp01(visualRect.left / boardSize.width);
    final top = _clamp01(visualRect.top / boardSize.height);
    final right = _clamp01(visualRect.right / boardSize.width);
    final bottom = _clamp01(visualRect.bottom / boardSize.height);

    return NormalizedRect(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  static void _validateSize(Size size, String name) {
    if (!size.width.isFinite || !size.height.isFinite) {
      throw ArgumentError.value(size, name, 'Must be finite');
    }
    if (size.width <= 0 || size.height <= 0) {
      throw ArgumentError.value(size, name, 'Must be positive');
    }
  }

  static double _clamp01(double value) => value.clamp(0, 1).toDouble();
}
