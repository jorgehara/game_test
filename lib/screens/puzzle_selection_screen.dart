import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/puzzle.dart';
import '../models/puzzle_category.dart';
import '../providers/puzzle_game_provider.dart';
import '../routes/app_routes.dart';
import '../services/asset_manifest_validator.dart';
import '../services/puzzle_asset_manifest_loader.dart';
import '../services/puzzle_catalog_service.dart';
import '../theme/pk_tokens.dart';
import '../widgets/pk_card.dart';
import '../widgets/pk_image_tile.dart';
import '../widgets/pk_scaffold.dart';

class PuzzleSelectionScreen extends StatefulWidget {
  const PuzzleSelectionScreen({
    super.key,
    this.assetManifest,
    this.existingAssetPaths = const {},
    this.assetBundle,
  });

  final List<AssetManifestEntry>? assetManifest;
  final Set<String> existingAssetPaths;
  final AssetBundle? assetBundle;

  @override
  State<PuzzleSelectionScreen> createState() => _PuzzleSelectionScreenState();
}

class _PuzzleSelectionScreenState extends State<PuzzleSelectionScreen> {
  late final Future<List<AssetManifestEntry>> _manifestFuture;

  @override
  void initState() {
    super.initState();
    _manifestFuture = widget.assetManifest == null
        ? PuzzleAssetManifestLoader.loadApproved(bundle: widget.assetBundle)
        : Future.value(widget.assetManifest);
  }

  @override
  Widget build(BuildContext context) {
    final puzzles = _sortedPlayablePuzzles();
    final spacing = context.pkSpacing;

    return PkScaffold(
      title: 'Selección',
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: FutureBuilder<List<AssetManifestEntry>>(
          future: _manifestFuture,
          builder: (context, snapshot) {
            final assetManifest = snapshot.data ?? const <AssetManifestEntry>[];
            final existingAssetPaths = widget.assetManifest == null
                ? PuzzleAssetManifestLoader.existingPathsFor(assetManifest)
                : widget.existingAssetPaths;

            return puzzles.isEmpty
                ? const _EmptyCatalog()
                : ListView.separated(
                    itemCount: puzzles.length + 1,
                    separatorBuilder: (context, _) =>
                        SizedBox(height: spacing.md),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _SelectionHeader();
                      }

                      return _PuzzleSelectionCard(
                        puzzle: puzzles[index - 1],
                        assetManifest: assetManifest,
                        existingAssetPaths: existingAssetPaths,
                      );
                    },
                  );
          },
        ),
      ),
    );
  }

  List<Puzzle> _sortedPlayablePuzzles() {
    final fantasyOrder = {
      PuzzleCategory.castles: 0,
      PuzzleCategory.princesses: 1,
      PuzzleCategory.unicorns: 2,
    };
    final puzzles = [...PuzzleCatalogService.playable()];
    puzzles.sort((a, b) {
      final categoryCompare = (fantasyOrder[a.category] ?? 10).compareTo(
        fantasyOrder[b.category] ?? 10,
      );
      if (categoryCompare != 0) return categoryCompare;
      return 0;
    });
    return List.unmodifiable(puzzles);
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader();

  @override
  Widget build(BuildContext context) {
    final spacing = context.pkSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegí tu puzzle',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: spacing.sm),
        Text(
          'Castillos, princesas, unicornios y más temas para jugar sin internet.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _PuzzleSelectionCard extends StatelessWidget {
  const _PuzzleSelectionCard({
    required this.puzzle,
    required this.assetManifest,
    required this.existingAssetPaths,
  });

  final Puzzle puzzle;
  final List<AssetManifestEntry> assetManifest;
  final Set<String> existingAssetPaths;

  @override
  Widget build(BuildContext context) {
    final spacing = context.pkSpacing;
    final colors = context.pkColors;
    final approvedAsset = PuzzleCatalogService.approvedAssetFor(
      puzzle,
      assetManifest,
      existingAssetPaths: existingAssetPaths,
    );

    return PkCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PkImageTile(
            label: 'Imagen segura de ${puzzle.name}',
            seed: puzzle.placeholderSeed,
            assetPath: approvedAsset?.thumbnailPath ?? approvedAsset?.path,
            cacheWidth: 256,
            cacheHeight: 256,
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  puzzle.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: spacing.sm),
                Wrap(
                  spacing: spacing.sm,
                  runSpacing: spacing.sm,
                  children: [
                    _MetadataChip(label: puzzle.category.label),
                    _MetadataChip(label: puzzle.levelLabel),
                    _MetadataChip(label: puzzle.progressLabel),
                  ],
                ),
                SizedBox(height: spacing.md),
                Text(
                  puzzle.placeholderLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.onSurface),
                ),
                SizedBox(height: spacing.md),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => _startPuzzle(context),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Jugar ${puzzle.name}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startPuzzle(BuildContext context) {
    context.read<PuzzleGameProvider>().selectPuzzle(puzzle.id);
    Navigator.pushNamed(context, AppRoutes.game);
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final spacing = context.pkSpacing;
    final colors = context.pkColors;
    final radius = context.pkRadius;

    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(radius.button),
          border: Border.all(color: colors.outline),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    final spacing = context.pkSpacing;

    return Center(
      child: PkCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PkImageTile(label: 'Catálogo vacío', seed: 0),
            SizedBox(height: spacing.md),
            Text(
              'No hay puzzles disponibles',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: spacing.sm),
            const Text('Probá volver al menú y entrar de nuevo.'),
          ],
        ),
      ),
    );
  }
}
