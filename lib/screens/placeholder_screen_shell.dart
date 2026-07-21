import 'package:flutter/material.dart';

import '../widgets/primary_action_button.dart';

class PlaceholderScreenShell extends StatelessWidget {
  const PlaceholderScreenShell({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    key: Key('screen-title-$title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 36),
                  PrimaryActionButton(label: buttonLabel, onPressed: onPressed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
