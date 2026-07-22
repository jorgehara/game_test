import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/main.dart';
import 'package:puzzle_kids/theme/pk_theme.dart';
import 'package:puzzle_kids/theme/pk_tokens.dart';
import 'package:puzzle_kids/widgets/pk_button.dart';
import 'package:puzzle_kids/widgets/pk_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('theme exposes semantic tokens and accessible controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PkTheme.light(),
        home: Scaffold(
          body: Center(
            child: PkCard(
              child: PkButton(label: 'Empezar aventura', onPressed: () {}),
            ),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(PkButton));
    final colors = context.pkColors;
    final contrast = colors.onPrimary.computeLuminance() == 0
        ? 21.0
        : (colors.onPrimary.computeLuminance() + 0.05) /
              (colors.primary.computeLuminance() + 0.05);

    expect(context.pkSpacing.md, 16);
    expect(context.pkRadius.card, 32);
    expect(context.pkButtonTokens.radius, context.pkRadius.button);
    expect(context.pkButtonTokens.primaryElevation, lessThanOrEqualTo(2));
    expect(context.pkButtonTokens.pressedOpacity, inInclusiveRange(0.08, 0.16));
    expect(context.pkMotion.standard, const Duration(milliseconds: 220));
    expect(contrast, greaterThanOrEqualTo(4.5));

    final buttonSize = tester.getSize(
      find.widgetWithText(ElevatedButton, 'Empezar aventura'),
    );
    expect(buttonSize.width, greaterThanOrEqualTo(48));
    expect(buttonSize.height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Empezar aventura'), findsWidgets);
  });

  testWidgets('theme exposes tokenized button state values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PkTheme.light(),
        home: Scaffold(
          body: PkButton(label: 'Continuar', onPressed: () {}),
        ),
      ),
    );

    final context = tester.element(find.byType(PkButton));
    final tokens = context.pkButtonTokens;
    final style = PkButton.styleFor(context, PkButtonVariant.primary);

    expect(tokens.minSize, const Size(48, 56));
    expect(tokens.horizontalPadding, 24);
    expect(tokens.radius, 28);
    expect(style.elevation?.resolve({}), tokens.primaryElevation);
    expect(
      style.elevation?.resolve({WidgetState.disabled}),
      tokens.disabledElevation,
    );
    expect(style.shadowColor?.resolve({})?.a, lessThan(0.35));
  });

  testWidgets('app provides light and dark tokenized themes', (tester) async {
    await tester.pumpWidget(const PuzzleKidsApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme?.extension<PkColors>(), isNotNull);
    expect(app.darkTheme?.extension<PkColors>(), isNotNull);
    expect(app.themeMode, ThemeMode.system);
  });
}
