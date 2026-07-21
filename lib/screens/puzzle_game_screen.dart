import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/puzzle_game_provider.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/puzzle_piece_tile.dart';

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = context.read<PuzzleGameProvider>();
    if (provider.status == PuzzleGameStatus.idle &&
        provider.playablePuzzles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || provider.status != PuzzleGameStatus.idle) {
          return;
        }
        provider.start(puzzleId: provider.playablePuzzles.first.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PuzzleGameProvider>(
          builder: (context, provider, _) {
            if (provider.status == PuzzleGameStatus.unavailable ||
                provider.currentPuzzle == null) {
              return _UnavailableGame(
                onBack: () => Navigator.maybePop(context),
              );
            }

            return _ReadyGame(provider: provider);
          },
        ),
      ),
    );
  }
}

class _ReadyGame extends StatelessWidget {
  const _ReadyGame({required this.provider});

  final PuzzleGameProvider provider;

  @override
  Widget build(BuildContext context) {
    final puzzle = provider.currentPuzzle!;
    final total = provider.pieces.length;

    return Padding(
      key: const Key('puzzle-game-screen'),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 780;
          final board = PuzzleBoard(
            puzzle: puzzle,
            pieces: provider.pieces,
            placedPositions: provider.placedPositions,
          );
          final tray = _PuzzleTray(provider: provider);

          return Column(
            children: [
              _GameHeader(provider: provider),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: board),
                          const SizedBox(width: 20),
                          SizedBox(width: 280, child: tray),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: board),
                          const SizedBox(height: 16),
                          SizedBox(height: 148, child: tray),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                provider.isCompleted
                    ? '¡Puzzle completo!'
                    : 'Elegí una pieza para mirar dónde va.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              Semantics(
                key: const Key('puzzle-progress'),
                label: 'Progreso ${provider.progressCount} de $total',
                child: Text('Progreso ${provider.progressCount}/$total'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.provider});

  final PuzzleGameProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        _LargeControl(
          key: const Key('puzzle-back-button'),
          label: 'Volver',
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.maybePop(context),
        ),
        Text(
          provider.currentPuzzle!.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        _LargeControl(
          key: const Key('puzzle-reset-button'),
          label: 'Reiniciar',
          icon: Icons.refresh_rounded,
          onPressed: provider.reset,
        ),
        _LargeControl(
          key: const Key('puzzle-sound-placeholder-button'),
          label: 'Sonido pronto',
          icon: Icons.volume_off_rounded,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _PuzzleTray extends StatelessWidget {
  const _PuzzleTray({required this.provider});

  final PuzzleGameProvider provider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bandeja de piezas',
      child: DecoratedBox(
        key: const Key('puzzle-tray'),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1B8),
          border: Border.all(color: const Color(0xFF6C3F00), width: 3),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final piece in provider.piecesInTray)
                PuzzlePieceTile(
                  key: Key('puzzle-piece-${piece.id}'),
                  piece: piece,
                  totalPieces: provider.pieces.length,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeControl extends StatelessWidget {
  const _LargeControl({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(148, 56),
          backgroundColor: const Color(0xFF3B2F8F),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _UnavailableGame extends StatelessWidget {
  const _UnavailableGame({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('puzzle-unavailable-state'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Puzzle no disponible',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Este puzzle todavía no está listo. Probemos con otro.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _LargeControl(
              key: const Key('puzzle-back-button'),
              label: 'Volver',
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
