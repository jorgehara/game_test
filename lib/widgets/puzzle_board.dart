import 'package:flutter/material.dart';

import '../models/grid_position.dart';
import '../models/puzzle.dart';
import '../models/puzzle_piece.dart';
import '../theme/pk_tokens.dart';
import 'puzzle_piece_geometry.dart';
import 'puzzle_piece_tile.dart';

abstract final class PuzzleBoardSurfaceTokens {
  static const boardBorderWidth = 2.0;
  static const slotDividerWidth = 1.0;
  static const placedPieceInset = 0.0;
  static const slotNumberFontSize = 28.0;
}

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.puzzle,
    required this.pieces,
    required this.placedPositions,
    this.pieceImageSource,
    this.boardMeasurementKey,
  });

  final Puzzle puzzle;
  final List<PuzzlePiece> pieces;
  final Map<String, GridPosition> placedPositions;
  final PuzzlePieceImageSource? pieceImageSource;
  final GlobalKey? boardMeasurementKey;

  @override
  Widget build(BuildContext context) {
    final grid = puzzle.grid;
    final aspectRatio = grid.columns / grid.rows;
    final colors = context.pkColors;
    final radius = context.pkRadius;

    return Semantics(
      label: 'Tablero del puzzle ${puzzle.name}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          var boardWidth = maxWidth;
          var boardHeight = boardWidth / aspectRatio;

          if (boardHeight > maxHeight) {
            boardHeight = maxHeight;
            boardWidth = boardHeight * aspectRatio;
          }

          final cellWidth = boardWidth / grid.columns;
          final cellHeight = boardHeight / grid.rows;

          return Center(
            child: SizedBox(
              key: boardMeasurementKey,
              width: boardWidth,
              height: boardHeight,
              child: SizedBox.expand(
                key: const Key('puzzle-board'),
                child: DecoratedBox(
                  key: const Key('puzzle-board-surface'),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.72),
                      width: PuzzleBoardSurfaceTokens.boardBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(radius.board),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      radius.board - PuzzleBoardSurfaceTokens.boardBorderWidth,
                    ),
                    child: Stack(
                      children: [
                        for (var row = 0; row < grid.rows; row += 1)
                          for (
                            var column = 0;
                            column < grid.columns;
                            column += 1
                          )
                            _Slot(
                              row: row,
                              column: column,
                              index: row * grid.columns + column,
                              left: column * cellWidth,
                              top: row * cellHeight,
                              width: cellWidth,
                              height: cellHeight,
                            ),
                        for (final piece in pieces)
                          if (placedPositions.containsKey(piece.id))
                            _PlacedPiece(
                              piece: piece,
                              totalPieces: pieces.length,
                              boardSize: Size(boardWidth, boardHeight),
                              imageSource: pieceImageSource,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlacedPiece extends StatelessWidget {
  const _PlacedPiece({
    required this.piece,
    required this.totalPieces,
    required this.boardSize,
    required this.imageSource,
  });

  final PuzzlePiece piece;
  final int totalPieces;
  final Size boardSize;
  final PuzzlePieceImageSource? imageSource;

  @override
  Widget build(BuildContext context) {
    final geometry = PuzzlePieceGeometry.forBoard(
      piece: piece,
      boardSize: boardSize,
    );

    return Positioned.fromRect(
      key: Key('puzzle-placed-piece-${piece.id}'),
      rect: geometry.visualRect,
      child: PuzzlePieceTile(
        piece: piece,
        totalPieces: totalPieces,
        imageSource: imageSource,
        geometry: geometry,
        expand: true,
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.row,
    required this.column,
    required this.index,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final int row;
  final int column;
  final int index;
  final double left;
  final double top;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.pkColors;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        container: true,
        label: 'Espacio ${index + 1}',
        child: Container(
          key: Key('puzzle-slot-$index'),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: index.isEven
                ? colors.surfaceAlt.withValues(alpha: 0.32)
                : colors.secondary.withValues(alpha: 0.10),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.36),
              width: PuzzleBoardSurfaceTokens.slotDividerWidth,
            ),
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: colors.outline.withValues(alpha: 0.56),
              fontSize: PuzzleBoardSurfaceTokens.slotNumberFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
