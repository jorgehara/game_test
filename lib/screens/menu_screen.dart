import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'placeholder_screen_shell.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreenShell(
      title: 'Menú',
      message: 'Elegí una aventura.',
      buttonLabel: 'Ver categorías',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.categories),
    );
  }
}
