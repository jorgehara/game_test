import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:puzzle_kids/providers/app_shell_provider.dart';
import 'package:puzzle_kids/providers/onboarding_provider.dart';
import 'package:puzzle_kids/providers/progress_provider.dart';
import 'package:puzzle_kids/providers/puzzle_game_provider.dart';
import 'package:puzzle_kids/providers/settings_provider.dart';
import 'package:puzzle_kids/routes/app_routes.dart';
import 'package:puzzle_kids/screens/puzzle_game_screen.dart';
import 'package:puzzle_kids/screens/puzzle_selection_screen.dart';
import 'package:puzzle_kids/theme/pk_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders accessible premium puzzle cards with metadata', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpSelection(tester);

    expect(find.text('Elegí tu puzzle'), findsOneWidget);
    expect(find.text('Castillo brillante'), findsOneWidget);
    expect(find.text('Castillos'), findsWidgets);
    expect(find.text('Nivel 2'), findsWidgets);
    expect(find.text('0/4 piezas'), findsWidgets);
    expect(
      find.bySemanticsLabel('Imagen segura de Castillo brillante'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);

    final playButton = find.widgetWithText(
      FilledButton,
      'Jugar Castillo brillante',
    );
    expect(playButton, findsOneWidget);
    expect(tester.getSize(playButton).height, greaterThanOrEqualTo(48));

    semantics.dispose();
  });

  testWidgets('starts selected puzzle within the selection flow', (
    tester,
  ) async {
    final provider = PuzzleGameProvider();

    await _pumpSelection(tester, provider: provider);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Jugar Castillo brillante'),
    );
    await tester.pumpAndSettle();

    expect(provider.currentPuzzle?.id, 'castle-bright');
    expect(find.byKey(const Key('puzzle-game-screen')), findsOneWidget);
  });
}

Future<void> _pumpSelection(
  WidgetTester tester, {
  PuzzleGameProvider? provider,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final onboarding = OnboardingProvider(prefs: prefs)..markLoaded();
  await onboarding.completeDragOnboarding();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppShellProvider>(create: (_) => const AppShellProvider()),
        ChangeNotifierProvider<PuzzleGameProvider>.value(
          value: provider ?? PuzzleGameProvider(),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (_) => ProgressProvider(prefs: prefs)..markLoaded(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(prefs: prefs)..markLoaded(),
        ),
        ChangeNotifierProvider<OnboardingProvider>.value(value: onboarding),
      ],
      child: MaterialApp(
        theme: PkTheme.light(),
        home: const PuzzleSelectionScreen(),
        routes: {AppRoutes.game: (_) => const PuzzleGameScreen()},
      ),
    ),
  );
  await tester.pumpAndSettle();
}
