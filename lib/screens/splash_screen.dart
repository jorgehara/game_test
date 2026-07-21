import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_shell_provider.dart';
import '../routes/app_routes.dart';
import 'placeholder_screen_shell.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appShell = context.read<AppShellProvider>();

    return PlaceholderScreenShell(
      title: appShell.appName,
      message: 'Jugá puzzles simples y divertidos.',
      buttonLabel: 'Empezar',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.menu),
    );
  }
}
