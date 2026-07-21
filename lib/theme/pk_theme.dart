import 'package:flutter/material.dart';

import 'pk_tokens.dart';

class PkTheme {
  const PkTheme._();

  static ThemeData light() => _theme(Brightness.light, PkColors.light);
  static ThemeData dark() => _theme(Brightness.dark, PkColors.dark);

  static ThemeData _theme(Brightness brightness, PkColors colors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      surface: colors.surface,
      onSurface: colors.onSurface,
      secondary: colors.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.surface,
      fontFamily: null,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PkRadius.standard.button),
          ),
        ),
      ),
      iconTheme: IconThemeData(color: colors.primary, size: 28),
      extensions: const [
        PkColors.light,
        PkSpacing.standard,
        PkRadius.standard,
        PkMotion.standardMotion,
      ],
    ).copyWith(
      extensions: [
        colors,
        PkSpacing.standard,
        PkRadius.standard,
        PkMotion.standardMotion,
      ],
    );
  }
}
