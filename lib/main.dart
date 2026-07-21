import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_shell_provider.dart';
import 'providers/puzzle_game_provider.dart';
import 'routes/app_routes.dart';
import 'theme/pk_theme.dart';

void main() {
  runApp(const PuzzleKidsApp());
}

class PuzzleKidsApp extends StatelessWidget {
  const PuzzleKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppShellProvider>(create: (_) => const AppShellProvider()),
        ChangeNotifierProvider<PuzzleGameProvider>(
          create: (_) => PuzzleGameProvider(),
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
  }
}
