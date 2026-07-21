import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/main.dart';
import 'package:puzzle_kids/routes/app_routes.dart';
import 'package:puzzle_kids/theme/pk_theme.dart';
import 'package:puzzle_kids/widgets/pk_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('phone keeps simple flow without primary sidebar', (
    tester,
  ) async {
    _setLogicalSize(tester, const Size(390, 800));

    await tester.pumpWidget(const PuzzleKidsApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pk-adaptive-sidebar')), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Empezar'), findsOneWidget);
  });

  testWidgets('tablet landscape shows one semantic adaptive sidebar only', (
    tester,
  ) async {
    _setLogicalSize(tester, const Size(960, 640));

    await tester.pumpWidget(const PuzzleKidsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Empezar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pk-adaptive-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('pk-open-drawer')), findsNothing);
    expect(find.byKey(const Key('pk-adaptive-drawer')), findsNothing);
    expect(
      find.bySemanticsLabel('Navegación principal de Puzzle Kids'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pk-nav-${AppRoutes.menu}')), findsOneWidget);
    expect(
      find.byKey(const Key('pk-nav-${AppRoutes.categories}')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('pk-nav-${AppRoutes.categories}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen-title-Categorías')), findsOneWidget);
    expect(
      find.byKey(const Key('pk-nav-selected-${AppRoutes.categories}')),
      findsOneWidget,
    );
  });

  testWidgets(
    'compact adaptive drawer closes with Android back before route pop',
    (tester) async {
      _setLogicalSize(tester, const Size(390, 800));

      await tester.pumpWidget(const PuzzleKidsApp());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Empezar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pk-open-drawer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pk-adaptive-drawer')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pk-adaptive-drawer')), findsNothing);
      expect(find.byKey(const Key('screen-title-Menú')), findsOneWidget);
    },
  );

  testWidgets('disableAnimations keeps compact nav usable without motion', (
    tester,
  ) async {
    _setLogicalSize(tester, const Size(390, 800));

    await tester.pumpWidget(const _ReducedMotionNavHarness());

    expect(find.byKey(const Key('screen-title-Menú')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pk-open-drawer')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pk-adaptive-drawer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pk-nav-${AppRoutes.categories}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen-title-Categorías')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pk-open-drawer')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pk-nav-selected-${AppRoutes.categories}')),
      findsOneWidget,
    );
  });

  testWidgets('compact shell tolerates large text without losing navigation', (
    tester,
  ) async {
    _setLogicalSize(tester, const Size(390, 800));

    await tester.pumpWidget(const _LargeTextNavHarness());

    expect(find.byKey(const Key('pk-open-drawer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pk-open-drawer')));
    await tester.pump();

    expect(find.byKey(const Key('pk-adaptive-drawer')), findsOneWidget);
    expect(
      find.byKey(const Key('pk-nav-${AppRoutes.categories}')),
      findsOneWidget,
    );
  });
}

void _setLogicalSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _ReducedMotionNavHarness extends StatelessWidget {
  const _ReducedMotionNavHarness();

  @override
  Widget build(BuildContext context) {
    return const _NavHarness(disableAnimations: true);
  }
}

class _LargeTextNavHarness extends StatelessWidget {
  const _LargeTextNavHarness();

  @override
  Widget build(BuildContext context) {
    return const _NavHarness(textScaleFactor: 1.6);
  }
}

class _NavHarness extends StatelessWidget {
  const _NavHarness({this.disableAnimations = false, this.textScaleFactor = 1});

  final bool disableAnimations;
  final double textScaleFactor;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PkTheme.light(),
      builder: (context, child) {
        final data = MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScaleFactor),
        );
        return MediaQuery(data: data, child: child!);
      },
      initialRoute: AppRoutes.menu,
      routes: {
        AppRoutes.menu: (_) => const _HarnessScreen(title: 'Menú'),
        AppRoutes.categories: (_) => const _HarnessScreen(title: 'Categorías'),
        AppRoutes.selection: (_) => const _HarnessScreen(title: 'Selección'),
        AppRoutes.game: (_) => const _HarnessScreen(title: 'Juego'),
      },
    );
  }
}

class _HarnessScreen extends StatelessWidget {
  const _HarnessScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return PkScaffold(
      title: title,
      child: Center(child: Text(title, key: Key('screen-title-$title'))),
    );
  }
}
