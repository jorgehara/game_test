import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/grid_position.dart';
import 'package:puzzle_kids/models/grid_spec.dart';
import 'package:puzzle_kids/models/normalized_rect.dart';
import 'package:puzzle_kids/models/puzzle_piece.dart';
import 'package:puzzle_kids/widgets/puzzle_piece_tile.dart';

void main() {
  group('PuzzlePieceTile', () {
    testWidgets(
      'keeps numbered fallback, tray size, and semantics by default',
      (tester) async {
        await tester.pumpWidget(_host(_tile(_piece2x2(0, 1), totalPieces: 4)));

        expect(find.text('2'), findsOneWidget);
        expect(find.bySemanticsLabel('Pieza 2 de 4'), findsOneWidget);
        expect(
          tester.getSize(find.byType(PuzzlePieceTile)),
          const Size(86, 86),
        );
        expect(
          find.byKey(const Key('puzzle-piece-image-piece-0-1')),
          findsNothing,
        );
      },
    );

    testWidgets('renders 2x2 crops from a shared local AssetImage', (
      tester,
    ) async {
      const source = PuzzlePieceImageSource(
        assetPath: 'assets/images/castles/castillo-princesa.webp',
        sourceWidth: 1024,
        sourceHeight: 1024,
      );

      await tester.pumpWidget(
        _host(
          Row(
            children: [
              _tile(_piece2x2(0, 0), totalPieces: 4, imageSource: source),
              _tile(_piece2x2(1, 1), totalPieces: 4, imageSource: source),
            ],
          ),
        ),
      );

      expect(
        find.byKey(const Key('puzzle-piece-image-piece-0-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('puzzle-piece-image-piece-1-1')),
        findsOneWidget,
      );

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(2));
      expect(
        images.map((image) => image.image),
        everyElement(isA<AssetImage>()),
      );
      expect(
        images.map((image) => (image.image as AssetImage).assetName).toSet(),
        {source.assetPath},
      );
      expect(images.map((image) => image.fit).toSet(), {BoxFit.cover});
      expect(
        find.descendant(
          of: find.byKey(const Key('puzzle-piece-image-piece-0-0')),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('puzzle-piece-image-piece-1-1')),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('structures 3x3 crop by scaling full covered puzzle space', (
      tester,
    ) async {
      const source = PuzzlePieceImageSource(
        assetPath: 'assets/images/castles/castillo-princesa.webp',
        sourceWidth: 1024,
        sourceHeight: 1024,
      );

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 90,
            height: 90,
            child: _tile(
              _piece(grid: GridSpec(rows: 3, columns: 3), row: 1, column: 2),
              totalPieces: 9,
              imageSource: source,
              expand: true,
            ),
          ),
        ),
      );

      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byKey(const Key('puzzle-piece-image-piece-1-2')),
          matching: find.byType(Transform),
        ),
      );

      expect(transform.transform.getTranslation().x, closeTo(-168, 0.001));
      expect(transform.transform.getTranslation().y, closeTo(-84, 0.001));

      final fullPuzzleBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byKey(const Key('puzzle-piece-image-piece-1-2')),
          matching: find.byKey(const Key('puzzle-piece-image-space-piece-1-2')),
        ),
      );
      expect(fullPuzzleBox.width, closeTo(252, 0.001));
      expect(fullPuzzleBox.height, closeTo(252, 0.001));
    });

    testWidgets('uses cover math for rectangular sources without stretching', (
      tester,
    ) async {
      const source = PuzzlePieceImageSource(
        assetPath: 'assets/images/castles/wide-castle.webp',
        sourceWidth: 1200,
        sourceHeight: 600,
      );

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 100,
            height: 80,
            child: _tile(
              _piece2x2(0, 1),
              totalPieces: 4,
              imageSource: source,
              expand: true,
            ),
          ),
        ),
      );

      final fullPuzzleBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byKey(const Key('puzzle-piece-image-piece-0-1')),
          matching: find.byKey(const Key('puzzle-piece-image-space-piece-0-1')),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));

      expect(fullPuzzleBox.width, 188);
      expect(fullPuzzleBox.height, 148);
      expect(image.fit, BoxFit.cover);
      expect(image.width, 188);
      expect(image.height, 148);
    });

    testWidgets('falls back while loading and after asset errors', (
      tester,
    ) async {
      const source = PuzzlePieceImageSource(
        assetPath: 'assets/images/missing.webp',
        sourceWidth: 1024,
        sourceHeight: 1024,
      );

      await tester.pumpWidget(
        _host(_tile(_piece2x2(0, 0), totalPieces: 4, imageSource: source)),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.bySemanticsLabel('Pieza 1 de 4'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.bySemanticsLabel('Pieza 1 de 4'), findsOneWidget);
    });

    testWidgets('falls back for unapproved image sources', (tester) async {
      const source = PuzzlePieceImageSource(
        assetPath: 'assets/images/castles/castillo-princesa.webp',
        sourceWidth: 1024,
        sourceHeight: 1024,
        approved: false,
      );

      await tester.pumpWidget(
        _host(_tile(_piece2x2(1, 0), totalPieces: 4, imageSource: source)),
      );

      expect(find.text('3'), findsOneWidget);
      expect(
        find.byKey(const Key('puzzle-piece-image-piece-1-0')),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Pieza 3 de 4'), findsOneWidget);
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

PuzzlePieceTile _tile(
  PuzzlePiece piece, {
  required int totalPieces,
  PuzzlePieceImageSource? imageSource,
  bool expand = false,
}) {
  return PuzzlePieceTile(
    piece: piece,
    totalPieces: totalPieces,
    imageSource: imageSource,
    expand: expand,
  );
}

PuzzlePiece _piece2x2(int row, int column) {
  return _piece(grid: GridSpec(rows: 2, columns: 2), row: row, column: column);
}

PuzzlePiece _piece({
  required GridSpec grid,
  required int row,
  required int column,
}) {
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
