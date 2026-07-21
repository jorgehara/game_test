import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'placeholder_screen_shell.dart';

class CelebrationScreen extends StatelessWidget {
  const CelebrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreenShell(
      title: '¡Bien hecho!',
      message: 'La celebración real llega en otro slice.',
      buttonLabel: 'Siguiente puzzle',
      onPressed: () => Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.selection,
        ModalRoute.withName(AppRoutes.menu),
      ),
    );
  }
}
