import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/main.dart';

void main() {
  testWidgets('PuzzleKidsApp renders splash surface', (tester) async {
    await tester.pumpWidget(const PuzzleKidsApp());

    expect(find.text('Puzzle Kids'), findsOneWidget);
    expect(find.text('Jugá puzzles simples y divertidos.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Empezar'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
  });

  testWidgets('placeholder flow reaches celebration and next puzzle', (
    tester,
  ) async {
    await tester.pumpWidget(const PuzzleKidsApp());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Empezar'));
    await tester.pumpAndSettle();
    expect(find.text('Menú'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Ver categorías'));
    await tester.pumpAndSettle();
    expect(find.text('Categorías'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Elegir puzzle'));
    await tester.pumpAndSettle();
    expect(find.text('Selección'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Jugar'));
    await tester.pumpAndSettle();
    expect(find.text('Juego'), findsOneWidget);
    expect(find.textContaining('pieza'), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Celebrar'));
    await tester.pumpAndSettle();
    expect(find.text('¡Bien hecho!'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Siguiente puzzle'));
    await tester.pumpAndSettle();
    expect(find.text('Selección'), findsOneWidget);
  });
}
