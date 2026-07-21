import 'dart:math' as math;

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
    final motionEnabled =
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

    return AlertDialog(
      key: const Key('completion-dialog'),
      icon: Stack(
        alignment: Alignment.center,
        children: [
          if (motionEnabled)
            SizedBox(
              key: const Key('completion-confetti'),
              width: 132,
              height: 88,
              child: CustomPaint(
                painter: _ConfettiPainter(colors.piecePalette),
              ),
            )
          else
            const SizedBox(
              key: Key('completion-static-success'),
              width: 132,
              height: 88,
            ),
          Icon(
            Icons.check_circle_rounded,
            size: 56,
            color: colors.success,
            semanticLabel: 'Puzzle completado',
          ),
        ],
      ),
      title: const Text('¡Lo lograste!', textAlign: TextAlign.center),
      content: Text(
        'Terminaste $puzzleName. Podés seguir jugando o volver cuando quieras.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actions: [
        TextButton(
          key: const Key('completion-dismiss-button'),
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cerrar'),
        ),
        TextButton.icon(
          key: const Key('completion-replay-button'),
          onPressed: onReplay,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Jugar de nuevo'),
        ),
        Padding(
          padding: EdgeInsets.only(left: spacing.xs),
          child: PkButton(
            key: const Key('completion-continue-button'),
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.palette);

  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 14; index += 1) {
      final angle = index * math.pi / 7;
      final radius = index.isEven ? size.width * 0.36 : size.width * 0.24;
      final center = Offset(
        size.width / 2 + math.cos(angle) * radius,
        size.height / 2 + math.sin(angle) * size.height * 0.34,
      );
      paint.color = palette[index % palette.length];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 8, height: 14),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}
