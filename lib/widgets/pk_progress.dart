import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';

class PkProgress extends StatelessWidget {
  const PkProgress({required this.value, required this.label, super.key});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pkColors;
    return Semantics(
      label: label,
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        color: colors.success,
        backgroundColor: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
