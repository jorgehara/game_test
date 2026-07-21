import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'placeholder_screen_shell.dart';

class PuzzleGameScreen extends StatelessWidget {
  const PuzzleGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreenShell(
      title: 'Juego',
      message: 'Acá va a vivir el puzzle. Todavía es una pantalla simple.',
      buttonLabel: 'Celebrar',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.celebration),
    );
  }
}
