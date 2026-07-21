import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';

class PkCard extends StatelessWidget {
  const PkCard({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.pkColors;
    final spacing = context.pkSpacing;
    final radius = context.pkRadius;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline, width: 2),
        borderRadius: BorderRadius.circular(radius.card),
        boxShadow: [
          BoxShadow(
            color: colors.outline.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(spacing.lg),
        child: child,
      ),
    );
  }
}
