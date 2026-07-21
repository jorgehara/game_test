import 'package:flutter/material.dart';

@immutable
class PkColors extends ThemeExtension<PkColors> {
  const PkColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.surface,
    required this.surfaceAlt,
    required this.onSurface,
    required this.outline,
    required this.success,
    required this.warning,
    required this.piecePalette,
  });

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color surface;
  final Color surfaceAlt;
  final Color onSurface;
  final Color outline;
  final Color success;
  final Color warning;
  final List<Color> piecePalette;

  static const light = PkColors(
    primary: Color(0xFF2E226E),
    onPrimary: Colors.white,
    secondary: Color(0xFF0F5F7A),
    surface: Color(0xFFFFFBF2),
    surfaceAlt: Color(0xFFFFE7A3),
    onSurface: Color(0xFF211A35),
    outline: Color(0xFF4B3A72),
    success: Color(0xFF176B3A),
    warning: Color(0xFF8A4A00),
    piecePalette: [
      Color(0xFFFFC857),
      Color(0xFF72D572),
      Color(0xFF4FC3E8),
      Color(0xFFFF8FB3),
      Color(0xFFC9A7FF),
      Color(0xFFFFA45B),
      Color(0xFF77DCCE),
      Color(0xFFFFE768),
      Color(0xFFB8E986),
    ],
  );

  static const dark = PkColors(
    primary: Color(0xFFFFD36A),
    onPrimary: Color(0xFF211A35),
    secondary: Color(0xFF8EE7FF),
    surface: Color(0xFF151124),
    surfaceAlt: Color(0xFF282042),
    onSurface: Color(0xFFFFFBF2),
    outline: Color(0xFFE4D7FF),
    success: Color(0xFFA7F0B5),
    warning: Color(0xFFFFD36A),
    piecePalette: [
      Color(0xFFFFD36A),
      Color(0xFFA7F0B5),
      Color(0xFF8EE7FF),
      Color(0xFFFFA6C8),
      Color(0xFFD8BEFF),
      Color(0xFFFFBE7A),
      Color(0xFFA6F0E4),
      Color(0xFFFFEE86),
      Color(0xFFCEF7A4),
    ],
  );

  @override
  PkColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? surface,
    Color? surfaceAlt,
    Color? onSurface,
    Color? outline,
    Color? success,
    Color? warning,
    List<Color>? piecePalette,
  }) {
    return PkColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      onSurface: onSurface ?? this.onSurface,
      outline: outline ?? this.outline,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      piecePalette: piecePalette ?? this.piecePalette,
    );
  }

  @override
  PkColors lerp(ThemeExtension<PkColors>? other, double t) {
    if (other is! PkColors) return this;
    return PkColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      piecePalette: t < 0.5 ? piecePalette : other.piecePalette,
    );
  }
}

@immutable
class PkSpacing extends ThemeExtension<PkSpacing> {
  const PkSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  static const standard = PkSpacing(
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 40,
  );

  @override
  PkSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return PkSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  PkSpacing lerp(ThemeExtension<PkSpacing>? other, double t) {
    if (other is! PkSpacing) return this;
    return PkSpacing(
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      xxl: lerpDouble(xxl, other.xxl, t),
    );
  }
}

@immutable
class PkRadius extends ThemeExtension<PkRadius> {
  const PkRadius({
    required this.button,
    required this.card,
    required this.board,
  });

  final double button;
  final double card;
  final double board;

  static const standard = PkRadius(button: 28, card: 32, board: 32);

  @override
  PkRadius copyWith({double? button, double? card, double? board}) {
    return PkRadius(
      button: button ?? this.button,
      card: card ?? this.card,
      board: board ?? this.board,
    );
  }

  @override
  PkRadius lerp(ThemeExtension<PkRadius>? other, double t) {
    if (other is! PkRadius) return this;
    return PkRadius(
      button: lerpDouble(button, other.button, t),
      card: lerpDouble(card, other.card, t),
      board: lerpDouble(board, other.board, t),
    );
  }
}

@immutable
class PkMotion extends ThemeExtension<PkMotion> {
  const PkMotion({required this.fast, required this.standard});

  final Duration fast;
  final Duration standard;

  static const standardMotion = PkMotion(
    fast: Duration(milliseconds: 150),
    standard: Duration(milliseconds: 220),
  );

  Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : duration;
  }

  @override
  PkMotion copyWith({Duration? fast, Duration? standard}) {
    return PkMotion(
      fast: fast ?? this.fast,
      standard: standard ?? this.standard,
    );
  }

  @override
  PkMotion lerp(ThemeExtension<PkMotion>? other, double t) {
    return t < 0.5 || other is! PkMotion ? this : other;
  }
}

extension PkThemeTokens on BuildContext {
  PkColors get pkColors =>
      Theme.of(this).extension<PkColors>() ?? PkColors.light;
  PkSpacing get pkSpacing =>
      Theme.of(this).extension<PkSpacing>() ?? PkSpacing.standard;
  PkRadius get pkRadius =>
      Theme.of(this).extension<PkRadius>() ?? PkRadius.standard;
  PkMotion get pkMotion =>
      Theme.of(this).extension<PkMotion>() ?? PkMotion.standardMotion;
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;
