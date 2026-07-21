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

  testWidgets('main flow reaches responsive puzzle game', (tester) async {
    await tester.pumpWidget(const PuzzleKidsApp());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Empezar'));
    await tester.pumpAndSettle();
    expect(find.text('Menú'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Ver categorías'));
    await tester.pumpAndSettle();
    expect(find.text('Categorías'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Elegir puzzle'));
    await tester.pumpAndSettle();
    expect(find.text('Elegí tu puzzle'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Jugar Castillo brillante'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('puzzle-game-screen')), findsOneWidget);
    expect(find.byKey(const Key('puzzle-board')), findsOneWidget);
    expect(find.byKey(const Key('puzzle-tray')), findsOneWidget);
    expect(find.textContaining('Progreso 0/'), findsOneWidget);
  });
}
