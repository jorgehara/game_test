import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/theme/pk_theme.dart';
import 'package:puzzle_kids/widgets/completion_dialog.dart';
import 'package:puzzle_kids/widgets/pk_button.dart';

void main() {
  testWidgets(
    'completion dialog applies primary and secondary button hierarchy',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PkTheme.light(),
          home: const Scaffold(
            body: CompletionDialog(
              puzzleName: 'Lion',
              onContinue: _noop,
              onReplay: _noop,
            ),
          ),
        ),
      );

      final buttons = tester
          .widgetList<PkButton>(find.byType(PkButton))
          .toList();
      expect(
        buttons.where(
          (button) =>
              button.label == 'Continuar' &&
              button.variant == PkButtonVariant.primary,
        ),
        hasLength(1),
      );
      expect(
        buttons.where(
          (button) =>
              button.label == 'Jugar de nuevo' &&
              button.variant == PkButtonVariant.tonal,
        ),
        hasLength(1),
      );
      expect(
        buttons.where(
          (button) =>
              button.label == 'Cerrar' &&
              button.variant == PkButtonVariant.ghost,
        ),
        hasLength(1),
      );

      final visibleText = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '');
      expect(visibleText.any(_containsEmoji), isFalse);
      expect(find.bySemanticsLabel('Continuar'), findsWidgets);
      expect(find.bySemanticsLabel('Jugar de nuevo'), findsWidgets);
      expect(find.bySemanticsLabel('Cerrar'), findsWidgets);
    },
  );
}

void _noop() {}

bool _containsEmoji(String value) {
  return value.runes.any(
    (rune) =>
        (rune >= 0x1F300 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF),
  );
}
