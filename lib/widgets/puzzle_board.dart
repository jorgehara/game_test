import 'package:flutter/material.dart';

import '../models/grid_position.dart';
import '../models/puzzle.dart';
import '../models/puzzle_piece.dart';
import 'puzzle_piece_tile.dart';

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.puzzle,
    required this.pieces,
    required this.placedPositions,
  });

  final Puzzle puzzle;
  final List<PuzzlePiece> pieces;
  final Map<String, GridPosition> placedPositions;

  @override
  Widget build(BuildContext context) {
    final grid = puzzle.grid;
    final aspectRatio = grid.columns / grid.rows;

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
              key: const Key('puzzle-board'),
              width: boardWidth,
              height: boardHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FF),
                  border: Border.all(color: const Color(0xFF12355B), width: 4),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      for (var row = 0; row < grid.rows; row += 1)
                        for (var column = 0; column < grid.columns; column += 1)
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
                          Positioned(
                            key: Key('puzzle-placed-piece-${piece.id}'),
                            left: piece.correctPosition.column * cellWidth + 6,
                            top: piece.correctPosition.row * cellHeight + 6,
                            width: cellWidth - 12,
                            height: cellHeight - 12,
                            child: PuzzlePieceTile(
                              piece: piece,
                              totalPieces: pieces.length,
                              expand: true,
                            ),
                          ),
                    ],
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
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        label: 'Espacio ${index + 1}',
        child: Container(
          key: Key('puzzle-slot-$index'),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: index.isEven
                ? const Color(0x66FFFFFF)
                : const Color(0x66BDEBFF),
            border: Border.all(color: const Color(0xFF12355B), width: 2),
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Color(0x9912355B),
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
