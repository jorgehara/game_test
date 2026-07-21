import 'package:flutter/material.dart';

import 'pk_button.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PkButton(label: label, onPressed: onPressed);
  }
}
