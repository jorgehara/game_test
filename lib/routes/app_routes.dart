import 'package:flutter/widgets.dart';

import '../screens/categories_screen.dart';
import '../screens/celebration_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/puzzle_game_screen.dart';
import '../screens/puzzle_selection_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const menu = '/menu';
  static const categories = '/categories';
  static const selection = '/selection';
  static const game = '/game';
  static const celebration = '/celebration';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    menu: (_) => const MenuScreen(),
    categories: (_) => const CategoriesScreen(),
    selection: (_) => const PuzzleSelectionScreen(),
    game: (_) => const PuzzleGameScreen(),
    celebration: (_) => const CelebrationScreen(),
  };
}
