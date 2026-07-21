import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'placeholder_screen_shell.dart';

class PuzzleSelectionScreen extends StatelessWidget {
  const PuzzleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreenShell(
      title: 'Selección',
      message: 'Después vas a elegir tu puzzle favorito.',
      buttonLabel: 'Jugar',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.game),
    );
  }
}
