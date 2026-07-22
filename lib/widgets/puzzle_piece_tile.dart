import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';
import '../theme/pk_tokens.dart';
import 'puzzle_piece_geometry.dart';
import 'puzzle_piece_shape.dart';

class PuzzlePieceImageSource {
  const PuzzlePieceImageSource({
    required this.assetPath,
    required this.sourceWidth,
    required this.sourceHeight,
    this.cacheWidth,
    this.approved = true,
  });

  final String assetPath;
  final int sourceWidth;
  final int sourceHeight;
  final int? cacheWidth;
  final bool approved;

  bool get canRender {
    return approved &&
        assetPath.trim().isNotEmpty &&
        !assetPath.startsWith('http://') &&
        !assetPath.startsWith('https://') &&
        sourceWidth > 0 &&
        sourceHeight > 0;
  }
}

class PuzzlePieceTile extends StatelessWidget {
  const PuzzlePieceTile({
    super.key,
    required this.piece,
    required this.totalPieces,
    this.imageSource,
    this.geometry,
    this.expand = false,
  });

  final PuzzlePiece piece;
  final int totalPieces;
  final PuzzlePieceImageSource? imageSource;
  final PuzzlePieceGeometry? geometry;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final number = piece.correctIndex + 1;
    final colors = context.pkColors;
    final fallback = _NumberedPieceFallback(number: number);
    final source = imageSource;
    final showImage = source != null && source.canRender && _supportsImageCrop;
    final fillColor =
        colors.piecePalette[piece.correctIndex % colors.piecePalette.length];
    final borderColor = colors.onSurface;
    final resolvedGeometry =
        geometry ?? PuzzlePieceGeometry.forTray(piece: piece);
    final tileSize = resolvedGeometry.viewportSize;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Pieza $number de $totalPieces',
      child: SizedBox(
        width: expand ? double.infinity : tileSize.width,
        height: expand ? double.infinity : tileSize.height,
        child: CustomPaint(
          key: Key('puzzle-piece-shape-${piece.id}'),
          painter: PuzzlePieceShapePainter(
            edges: piece.edges,
            fillColor: fillColor,
            borderColor: borderColor,
            borderWidth: 3,
            shadowColor: colors.outline.withValues(alpha: 0.18),
            shadowBlurRadius: 4,
            shadowOffset: const Offset(0, 2),
            cellRectInViewport: resolvedGeometry.cellRectInViewport,
          ),
          foregroundPainter: resolvedGeometry.paintInternalOutline
              ? PuzzlePieceShapePainter(
                  edges: piece.edges,
                  fillColor: fillColor,
                  borderColor: borderColor,
                  borderWidth: 3,
                  paintFill: false,
                  cellRectInViewport: resolvedGeometry.cellRectInViewport,
                )
              : null,
          child: ClipPath(
            clipper: PuzzlePieceShapeClipper(
              edges: piece.edges,
              cellRectInViewport: resolvedGeometry.cellRectInViewport,
            ),
            child: ColoredBox(
              color: fillColor,
              child: showImage
                  ? _PuzzlePieceImageCrop(
                      key: Key('puzzle-piece-image-${piece.id}'),
                      piece: piece,
                      geometry: resolvedGeometry,
                      imageSource: source,
                      loadingFallback: fallback,
                    )
                  : Center(child: fallback),
            ),
          ),
        ),
      ),
    );
  }

  bool get _supportsImageCrop {
    final grid = piece.correctPosition.grid;

    return grid.rows == grid.columns &&
        (grid.rows == 1 || grid.rows == 2 || grid.rows == 3);
  }
}

class _PuzzlePieceImageCrop extends StatelessWidget {
  const _PuzzlePieceImageCrop({
    super.key,
    required this.piece,
    required this.geometry,
    required this.imageSource,
    required this.loadingFallback,
  });

  final PuzzlePiece piece;
  final PuzzlePieceGeometry geometry;
  final PuzzlePieceImageSource imageSource;
  final Widget loadingFallback;

  @override
  Widget build(BuildContext context) {
    final crop = geometry.sourceRect;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;
          final fullPuzzleWidth = viewportWidth / crop.width;
          final fullPuzzleHeight = viewportHeight / crop.height;

          return OverflowBox(
            minWidth: fullPuzzleWidth,
            maxWidth: fullPuzzleWidth,
            minHeight: fullPuzzleHeight,
            maxHeight: fullPuzzleHeight,
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(
                -crop.left * fullPuzzleWidth,
                -crop.top * fullPuzzleHeight,
              ),
              child: SizedBox(
                key: Key('puzzle-piece-image-space-${piece.id}'),
                width: fullPuzzleWidth,
                height: fullPuzzleHeight,
                child: ExcludeSemantics(
                  child: Image.asset(
                    imageSource.assetPath,
                    width: fullPuzzleWidth,
                    height: fullPuzzleHeight,
                    fit: BoxFit.cover,
                    cacheWidth: imageSource.cacheWidth,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            return child;
                          }

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              child,
                              Center(child: loadingFallback),
                            ],
                          );
                        },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: loadingFallback);
                    },
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

class _NumberedPieceFallback extends StatelessWidget {
  const _NumberedPieceFallback({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = context.pkColors;

    return Text(
      '$number',
      style: TextStyle(
        color: colors.onSurface,
        fontSize: 30,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
