import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/theme/pk_theme.dart';
import 'package:puzzle_kids/theme/pk_tokens.dart';
import 'package:puzzle_kids/widgets/pk_button.dart';

void main() {
  testWidgets('variants resolve distinct structural styles', (tester) async {
    await tester.pumpWidget(
      _Harness(
        child: Column(
          children: [
            PkButton(
              key: const Key('primary'),
              label: 'Continuar',
              onPressed: () {},
            ),
            PkButton(
              key: const Key('tonal'),
              label: 'Reiniciar',
              variant: PkButtonVariant.tonal,
              onPressed: () {},
            ),
            PkButton(
              key: const Key('ghost'),
              label: 'Volver',
              variant: PkButtonVariant.ghost,
              onPressed: () {},
            ),
            PkButton(
              key: const Key('icon'),
              label: 'Sonido pronto',
              icon: Icons.volume_off_rounded,
              variant: PkButtonVariant.icon,
              semanticLabel: 'Sonido pronto',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    final context = tester.element(find.byType(Column));
    final primary = PkButton.styleFor(context, PkButtonVariant.primary);
    final tonal = PkButton.styleFor(context, PkButtonVariant.tonal);
    final ghost = PkButton.styleFor(context, PkButtonVariant.ghost);
    final icon = PkButton.styleFor(context, PkButtonVariant.icon);

    expect(
      primary.backgroundColor?.resolve({}),
      isNot(tonal.backgroundColor?.resolve({})),
    );
    expect(ghost.elevation?.resolve({}), 0);
    expect(icon.minimumSize?.resolve({}), const Size(48, 48));
    expect(find.bySemanticsLabel('Sonido pronto'), findsWidgets);
  });

  testWidgets(
    'pressed, focused, and disabled states resolve through WidgetState',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _Harness(
          child: Column(
            children: [
              PkButton(
                key: const Key('enabled'),
                label: 'Continuar',
                onPressed: () => taps += 1,
              ),
              const PkButton(
                key: Key('disabled'),
                label: 'Bloqueado',
                onPressed: null,
              ),
            ],
          ),
        ),
      );

      final context = tester.element(find.byKey(const Key('enabled')));
      final style = PkButton.styleFor(context, PkButtonVariant.primary);
      expect(
        style.overlayColor?.resolve({WidgetState.pressed}),
        isNot(style.overlayColor?.resolve({})),
      );
      expect(
        style.side?.resolve({WidgetState.focused})?.width,
        greaterThan(style.side?.resolve({})?.width ?? 0),
      );

      await tester.tap(find.byKey(const Key('disabled')));
      await tester.pump();

      expect(taps, 0);
      final semantics = tester.widget<Semantics>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.label == 'Bloqueado' &&
                  widget.properties.enabled == false,
            )
            .first,
      );
      expect(semantics.properties.enabled, isFalse);
    },
  );

  testWidgets('buttons keep 48dp target and 4/8dp token rhythm', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(
        child: Column(
          children: [
            PkButton(label: 'Grande', onPressed: () {}),
            PkButton(
              label: 'Compacto',
              size: PkButtonSize.compact,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    for (final label in ['Grande', 'Compacto']) {
      final rect = tester.getRect(find.text(label));
      final button = tester.getRect(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.width, greaterThanOrEqualTo(48));
      expect(button.height, greaterThanOrEqualTo(48));
      expect(button.width - rect.width, greaterThanOrEqualTo(8));
    }

    final tokens = tester.element(find.text('Grande')).pkButtonTokens;
    expect(tokens.minSize, const Size(48, 56));
    expect(tokens.compactMinSize, const Size(48, 48));
    expect(tokens.gap, 8);
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PkTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
