import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/main.dart';
import 'package:puzzle_kids/providers/onboarding_provider.dart';
import 'package:puzzle_kids/providers/progress_provider.dart';
import 'package:puzzle_kids/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PuzzleKidsApp renders splash surface', (tester) async {
    await tester.pumpWidget(const PuzzleKidsApp());
    await tester.pumpAndSettle();

    expect(find.text('Puzzle Kids'), findsOneWidget);
    expect(find.text('Jugá puzzles simples y divertidos.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Empezar'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
  });

  testWidgets('hydrates local preferences before exposing app providers', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'pk.completedPuzzleIds': ['lion'],
      'pk.soundEnabled': false,
      'pk.musicEnabled': false,
      'pk.vibrationEnabled': true,
      'pk.dragOnboardingSeen': true,
    });

    await tester.pumpWidget(const PuzzleKidsApp());

    expect(find.byKey(const Key('local-preferences-loading')), findsOneWidget);
    expect(find.byType(MaterialApp), findsNothing);

    await tester.pumpAndSettle();

    final appContext = tester.element(find.byType(MaterialApp));
    final progress = appContext.read<ProgressProvider>();
    final settings = appContext.read<SettingsProvider>();
    final onboarding = appContext.read<OnboardingProvider>();

    expect(progress.isLoaded, isTrue);
    expect(progress.isCompleted('lion'), isTrue);
    expect(settings.isLoaded, isTrue);
    expect(settings.soundEnabled, isFalse);
    expect(settings.musicEnabled, isFalse);
    expect(settings.vibrationEnabled, isTrue);
    expect(onboarding.isLoaded, isTrue);
    expect(onboarding.shouldShowDragOnboarding, isFalse);
  });

  testWidgets('main flow reaches responsive puzzle game', (tester) async {
    await tester.pumpWidget(const PuzzleKidsApp());
    await tester.pumpAndSettle();

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
