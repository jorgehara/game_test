import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_position.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/normalized_rect.dart';
import 'package:puzzle_kids/models/puzzle.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';
import 'package:puzzle_kids/models/puzzle_piece.dart';
import 'package:puzzle_kids/widgets/puzzle_board.dart';
import 'package:puzzle_kids/widgets/puzzle_piece_tile.dart';

void main() {
  group('PuzzleBoard', () {
    testWidgets(
      'passes one approved source to placed 1x1, 2x2, and 3x3 pieces',
      (tester) async {
        const source = PuzzlePieceImageSource(
          assetPath: 'assets/images/castles/board-approved-castle.webp',
          sourceWidth: 1024,
          sourceHeight: 1024,
        );

        for (final grid in [
          GridSpec(rows: 1, columns: 1),
          GridSpec(rows: 2, columns: 2),
          GridSpec(rows: 3, columns: 3),
        ]) {
          final pieces = _pieces(grid);

          await tester.pumpWidget(
            _host(
              PuzzleBoard(
                puzzle: _puzzle(grid),
                pieces: pieces,
                placedPositions: {
                  for (final piece in pieces) piece.id: piece.correctPosition,
                },
                pieceImageSource: source,
              ),
            ),
          );

          final images = tester.widgetList<Image>(find.byType(Image)).toList();

          expect(images, hasLength(grid.pieceCount));
          expect(
            images
                .map((image) => (image.image as AssetImage).assetName)
                .toSet(),
            {source.assetPath},
          );
        }
      },
    );

    testWidgets('keeps rectangular source cover-crop without stretching', (
      tester,
    ) async {
      const source = PuzzlePieceImageSource(
        assetPath: 'assets/images/castles/wide-castle.webp',
        sourceWidth: 1200,
        sourceHeight: 600,
      );
      final grid = GridSpec(rows: 2, columns: 2);
      final piece = _piece(grid, row: 0, column: 1);

      await tester.pumpWidget(
        _host(
          PuzzleBoard(
            puzzle: _puzzle(grid),
            pieces: [piece],
            placedPositions: {piece.id: piece.correctPosition},
            pieceImageSource: source,
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final imageSpace = tester.widget<SizedBox>(
        find.byKey(Key('puzzle-piece-image-space-${piece.id}')),
      );

      expect(image.fit, BoxFit.cover);
      expect(image.width, imageSpace.width);
      expect(image.height, imageSpace.height);
      expect(image.width, closeTo(image.height!, 0.001));
    });

    testWidgets('falls back when source is missing or unsupported', (
      tester,
    ) async {
      const source = PuzzlePieceImageSource(
        assetPath: 'assets/images/castles/board-approved-castle.webp',
        sourceWidth: 1024,
        sourceHeight: 1024,
      );
      final unsupportedGrid = GridSpec(rows: 2, columns: 3);
      final piece = _piece(unsupportedGrid, row: 0, column: 1);

      await tester.pumpWidget(
        _host(
          PuzzleBoard(
            puzzle: _puzzle(unsupportedGrid),
            pieces: [piece],
            placedPositions: {piece.id: piece.correctPosition},
          ),
        ),
      );

      expect(find.text('2'), findsWidgets);
      expect(find.byType(Image), findsNothing);

      await tester.pumpWidget(
        _host(
          PuzzleBoard(
            puzzle: _puzzle(unsupportedGrid),
            pieces: [piece],
            placedPositions: {piece.id: piece.correctPosition},
            pieceImageSource: source,
          ),
        ),
      );

      expect(find.text('2'), findsWidgets);
      expect(find.byType(Image), findsNothing);
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 360, height: 360, child: child)),
  );
}

Puzzle _puzzle(GridSpec grid) {
  return Puzzle(
    id: 'castillo-princesa',
    name: 'Castillo princesa',
    category: PuzzleCategory.castles,
    imagePath: 'assets/images/castles/castillo-princesa.webp',
    difficulty: PuzzleDifficulty.level(grid.pieceCount == 9 ? 4 : 2),
    grid: grid,
  );
}

List<PuzzlePiece> _pieces(GridSpec grid) {
  return [
    for (var row = 0; row < grid.rows; row += 1)
      for (var column = 0; column < grid.columns; column += 1)
        _piece(grid, row: row, column: column),
  ];
}

PuzzlePiece _piece(GridSpec grid, {required int row, required int column}) {
  return PuzzlePiece(
    id: 'piece-$row-$column',
    correctPosition: GridPosition(row: row, column: column, grid: grid),
    crop: NormalizedRect(
      left: column / grid.columns,
      top: row / grid.rows,
      width: 1 / grid.columns,
      height: 1 / grid.rows,
    ),
  );
}
