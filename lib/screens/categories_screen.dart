import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'placeholder_screen_shell.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreenShell(
      title: 'Categorías',
      message: 'Animales, vehículos y formas estarán acá.',
      buttonLabel: 'Elegir puzzle',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.selection),
    );
  }
}
