import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/pk_tokens.dart';

class PkScaffold extends StatelessWidget {
  const PkScaffold({
    required this.title,
    required this.child,
    super.key,
    this.showNavigation = true,
  });

  final String title;
  final Widget child;
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = showNavigation && width >= 780;
    final isCompactNav = showNavigation && !isWide;
    final body = SafeArea(child: child);

    return Scaffold(
      appBar: isCompactNav
          ? AppBar(
              title: Text(title),
              leading: Builder(
                builder: (context) => IconButton(
                  key: const Key('pk-open-drawer'),
                  tooltip: 'Abrir navegación',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            )
          : null,
      drawer: isCompactNav ? const _PkAdaptiveDrawer() : null,
      body: isWide
          ? Row(
              children: [
                const _PkAdaptiveSidebar(),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}

class _PkAdaptiveSidebar extends StatelessWidget {
  const _PkAdaptiveSidebar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Navegación principal de Puzzle Kids',
      child: Material(
        key: const Key('pk-adaptive-sidebar'),
        color: context.pkColors.surfaceAlt,
        child: const SizedBox(
          width: 248,
          child: SafeArea(child: _PkNavList(compact: false)),
        ),
      ),
    );
  }
}

class _PkAdaptiveDrawer extends StatelessWidget {
  const _PkAdaptiveDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: const Key('pk-adaptive-drawer'),
      child: Semantics(
        label: 'Navegación principal de Puzzle Kids',
        child: const _PkNavList(compact: true),
      ),
    );
  }
}

class _PkNavList extends StatelessWidget {
  const _PkNavList({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spacing = context.pkSpacing;
    return ListView(
      padding: EdgeInsets.all(spacing.md),
      children: [
        Text('Puzzle Kids', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: spacing.md),
        for (final item in _items) _PkNavItem(item: item, closeDrawer: compact),
      ],
    );
  }
}

class _PkNavItem extends StatelessWidget {
  const _PkNavItem({required this.item, required this.closeDrawer});

  final _PkNavEntry item;
  final bool closeDrawer;

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final selected = currentRoute == item.route;
    final colors = context.pkColors;
    final content = ListTile(
      key: Key('pk-nav-${item.route}'),
      selected: selected,
      leading: Icon(
        item.icon,
        color: selected ? colors.onPrimary : colors.primary,
      ),
      title: RichText(
        text: TextSpan(
          text: item.label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: selected ? colors.onPrimary : colors.onSurface,
          ),
        ),
      ),
      selectedTileColor: colors.primary,
      selectedColor: colors.onPrimary,
      textColor: colors.onSurface,
      minTileHeight: 56,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.pkRadius.button),
      ),
      onTap: () {
        if (closeDrawer) Navigator.pop(context);
        if (currentRoute == item.route) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          item.route,
          ModalRoute.withName(AppRoutes.menu),
        );
      },
    );

    return Semantics(
      selected: selected,
      label: item.label,
      child: selected
          ? KeyedSubtree(
              key: Key('pk-nav-selected-${item.route}'),
              child: content,
            )
          : content,
    );
  }
}

class _PkNavEntry {
  const _PkNavEntry({
    required this.route,
    required this.label,
    required this.icon,
  });
  final String route;
  final String label;
  final IconData icon;
}

const _items = [
  _PkNavEntry(route: AppRoutes.menu, label: 'Menú', icon: Icons.home_rounded),
  _PkNavEntry(
    route: AppRoutes.categories,
    label: 'Categorías',
    icon: Icons.category_rounded,
  ),
  _PkNavEntry(
    route: AppRoutes.selection,
    label: 'Selección',
    icon: Icons.grid_view_rounded,
  ),
  _PkNavEntry(
    route: AppRoutes.game,
    label: 'Juego',
    icon: Icons.extension_rounded,
  ),
];
