import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';

enum PkButtonVariant { primary, tonal, ghost, icon }

enum PkButtonSize { regular, compact }

class PkButton extends StatelessWidget {
  const PkButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.variant = PkButtonVariant.primary,
    this.size = PkButtonSize.regular,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PkButtonVariant variant;
  final PkButtonSize size;
  final String? semanticLabel;

  static ButtonStyle styleFor(
    BuildContext context,
    PkButtonVariant variant, {
    PkButtonSize size = PkButtonSize.regular,
  }) {
    final colors = context.pkColors;
    final tokens = context.pkButtonTokens;
    final scheme = Theme.of(context).colorScheme;
    final minimumSize =
        size == PkButtonSize.compact || variant == PkButtonVariant.icon
        ? tokens.compactMinSize
        : tokens.minSize;
    final horizontalPadding = size == PkButtonSize.compact
        ? tokens.compactHorizontalPadding
        : tokens.horizontalPadding;

    final (:background, :foreground, :elevation) = switch (variant) {
      PkButtonVariant.primary => (
        background: colors.primary,
        foreground: colors.onPrimary,
        elevation: tokens.primaryElevation,
      ),
      PkButtonVariant.tonal => (
        background: colors.surfaceAlt,
        foreground: colors.primary,
        elevation: tokens.tonalElevation,
      ),
      PkButtonVariant.ghost || PkButtonVariant.icon => (
        background: Colors.transparent,
        foreground: colors.primary,
        elevation: 0.0,
      ),
    };

    return ButtonStyle(
      animationDuration: context.pkMotion.fast,
      minimumSize: WidgetStatePropertyAll(minimumSize),
      tapTargetSize: MaterialTapTargetSize.padded,
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: tokens.verticalPadding,
        ),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      iconSize: const WidgetStatePropertyAll(24),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.onSurface.withValues(alpha: tokens.disabledOpacity)
            : foreground,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.onSurface.withValues(alpha: 0.10)
            : background,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.onSurface.withValues(alpha: tokens.disabledOpacity)
            : foreground,
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return Colors.transparent;
        if (states.contains(WidgetState.pressed)) {
          return foreground.withValues(alpha: tokens.pressedOpacity);
        }
        if (states.contains(WidgetState.focused)) {
          return foreground.withValues(alpha: tokens.focusOpacity);
        }
        return Colors.transparent;
      }),
      elevation: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? tokens.disabledElevation
            : elevation,
      ),
      shadowColor: WidgetStatePropertyAll(
        scheme.shadow.withValues(
          alpha: variant == PkButtonVariant.primary ? 0.24 : 0,
        ),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(
            color: colors.secondary,
            width: tokens.focusOutlineWidth,
          );
        }
        if (variant == PkButtonVariant.ghost ||
            variant == PkButtonVariant.icon) {
          return BorderSide(color: colors.outline.withValues(alpha: 0.28));
        }
        return BorderSide.none;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticLabel ?? label;
    final style = styleFor(context, variant, size: size);
    final button = icon == null
        ? ElevatedButton(style: style, onPressed: onPressed, child: Text(label))
        : ElevatedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: effectiveLabel,
      child: button,
    );
  }
}
