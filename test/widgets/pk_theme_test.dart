import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/main.dart';
import 'package:puzzle_kids/theme/pk_theme.dart';
import 'package:puzzle_kids/theme/pk_tokens.dart';
import 'package:puzzle_kids/widgets/pk_button.dart';
import 'package:puzzle_kids/widgets/pk_card.dart';

void main() {
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
    expect(context.pkMotion.standard, const Duration(milliseconds: 220));
    expect(contrast, greaterThanOrEqualTo(4.5));

    final buttonSize = tester.getSize(
      find.widgetWithText(ElevatedButton, 'Empezar aventura'),
    );
    expect(buttonSize.width, greaterThanOrEqualTo(48));
    expect(buttonSize.height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Empezar aventura'), findsOneWidget);
  });

  testWidgets('app provides light and dark tokenized themes', (tester) async {
    await tester.pumpWidget(const PuzzleKidsApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme?.extension<PkColors>(), isNotNull);
    expect(app.darkTheme?.extension<PkColors>(), isNotNull);
    expect(app.themeMode, ThemeMode.system);
  });
}
