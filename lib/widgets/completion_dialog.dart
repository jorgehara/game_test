import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';
import 'pk_button.dart';

class CompletionDialog extends StatelessWidget {
  const CompletionDialog({
    required this.puzzleName,
    required this.onContinue,
    required this.onReplay,
    super.key,
  });

  final String puzzleName;
  final VoidCallback onContinue;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final colors = context.pkColors;
    final spacing = context.pkSpacing;

    return AlertDialog(
      key: const Key('completion-dialog'),
      icon: Icon(
        Icons.check_circle_rounded,
        size: 56,
        color: colors.success,
        semanticLabel: 'Puzzle completado',
      ),
      title: const Text('¡Lo lograste!', textAlign: TextAlign.center),
      content: Text(
        'Terminaste $puzzleName. Podés seguir jugando o volver cuando quieras.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actions: [
        PkButton(
          key: const Key('completion-dismiss-button'),
          label: 'Cerrar',
          variant: PkButtonVariant.ghost,
          size: PkButtonSize.compact,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        PkButton(
          key: const Key('completion-replay-button'),
          label: 'Jugar de nuevo',
          variant: PkButtonVariant.tonal,
          size: PkButtonSize.compact,
          semanticLabel: 'Jugar de nuevo',
          onPressed: onReplay,
          icon: Icons.refresh_rounded,
        ),
        Padding(
          padding: EdgeInsets.only(left: spacing.xs),
          child: PkButton(
            key: const Key('completion-continue-button'),
            label: 'Continuar',
            variant: PkButtonVariant.primary,
            icon: Icons.arrow_forward_rounded,
            semanticLabel: 'Continuar',
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}
