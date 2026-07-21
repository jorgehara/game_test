import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';
import '../widgets/pk_card.dart';
import '../widgets/pk_scaffold.dart';
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
    final spacing = context.pkSpacing;
    return PkScaffold(
      title: title,
      showNavigation: title != 'Puzzle Kids',
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: PkCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    key: Key('screen-title-$title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  SizedBox(height: spacing.lg),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: spacing.xl),
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
