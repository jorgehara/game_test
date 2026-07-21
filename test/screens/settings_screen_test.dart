import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:puzzle_kids/providers/onboarding_provider.dart';
import 'package:puzzle_kids/providers/settings_provider.dart';
import 'package:puzzle_kids/screens/settings_screen.dart';
import 'package:puzzle_kids/theme/pk_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('updates local UX preferences without audio playback', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsProvider(prefs: prefs);
    final onboarding = OnboardingProvider(prefs: prefs)..markLoaded();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<OnboardingProvider>.value(value: onboarding),
        ],
        child: MaterialApp(
          theme: PkTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Sonidos'), findsOneWidget);
    expect(find.text('Música'), findsOneWidget);
    expect(find.text('Vibración'), findsOneWidget);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Sonidos'));
    await tester.pumpAndSettle();

    expect(settings.soundEnabled, isFalse);
  });

  testWidgets('replays drag onboarding from settings', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsProvider(prefs: prefs);
    final onboarding = OnboardingProvider(prefs: prefs)..markLoaded();
    await onboarding.completeDragOnboarding();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<OnboardingProvider>.value(value: onboarding),
        ],
        child: MaterialApp(
          theme: PkTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.drag(find.byType(ListView).last, const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ver tutorial'));
    await tester.pumpAndSettle();

    expect(onboarding.shouldShowDragOnboarding, isTrue);
  });
}
