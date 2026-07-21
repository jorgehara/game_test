import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_shell_provider.dart';
import 'providers/local_preferences_bootstrap.dart';
import 'providers/onboarding_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/puzzle_game_provider.dart';
import 'providers/settings_provider.dart';
import 'routes/app_routes.dart';
import 'theme/pk_theme.dart';

void main() {
  runApp(const PuzzleKidsApp());
}

class PuzzleKidsApp extends StatelessWidget {
  const PuzzleKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HydratedPuzzleKidsApp();
  }
}

class _HydratedPuzzleKidsApp extends StatefulWidget {
  const _HydratedPuzzleKidsApp();

  @override
  State<_HydratedPuzzleKidsApp> createState() => _HydratedPuzzleKidsAppState();
}

class _HydratedPuzzleKidsAppState extends State<_HydratedPuzzleKidsApp> {
  late final Future<LocalPreferencesBootstrap> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = LocalPreferencesBootstrap.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocalPreferencesBootstrap>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        final bootstrap = snapshot.data;
        if (bootstrap == null) {
          return const _LocalPreferencesLoadingShell();
        }

        return MultiProvider(
          providers: [
            Provider<AppShellProvider>(create: (_) => const AppShellProvider()),
            ChangeNotifierProvider<PuzzleGameProvider>(
              create: (_) => PuzzleGameProvider(),
            ),
            ChangeNotifierProvider<ProgressProvider>.value(
              value: bootstrap.progress,
            ),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: bootstrap.settings,
            ),
            ChangeNotifierProvider<OnboardingProvider>.value(
              value: bootstrap.onboarding,
            ),
          ],
          child: MaterialApp(
            title: 'Puzzle Kids',
            debugShowCheckedModeBanner: false,
            theme: PkTheme.light(),
            darkTheme: PkTheme.dark(),
            themeMode: ThemeMode.system,
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
          ),
        );
      },
    );
  }
}

class _LocalPreferencesLoadingShell extends StatelessWidget {
  const _LocalPreferencesLoadingShell();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        key: Key('local-preferences-loading'),
        color: Colors.white,
        child: Center(
          child: Semantics(
            label: 'Cargando preferencias locales',
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
