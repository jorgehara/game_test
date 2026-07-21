import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_shell_provider.dart';
import 'providers/puzzle_game_provider.dart';
import 'routes/app_routes.dart';

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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFFBF2),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(220, 64),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
