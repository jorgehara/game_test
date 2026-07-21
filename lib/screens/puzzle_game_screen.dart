import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/puzzle_piece.dart';
import '../providers/puzzle_game_provider.dart';
import '../routes/app_routes.dart';
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

class _ReadyGame extends StatefulWidget {
  const _ReadyGame({required this.provider});

  final PuzzleGameProvider provider;

  @override
  State<_ReadyGame> createState() => _ReadyGameState();
}

class _ReadyGameState extends State<_ReadyGame> {
  static const _snapThreshold = 0.10;
  static const _returnDuration = Duration(milliseconds: 300);

  final _stackKey = GlobalKey();
  final _boardKey = GlobalKey();
  _DragState? _drag;
  var _gestureVersion = 0;
  var _completionNavigationScheduled = false;

  PuzzleGameProvider get provider => widget.provider;

  @override
  Widget build(BuildContext context) {
    _scheduleCompletionNavigation(context);

    final puzzle = provider.currentPuzzle!;
    final total = provider.pieces.length;

    return Stack(
      key: _stackKey,
      children: [
        Padding(
          key: const Key('puzzle-game-screen'),
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 780;
              final board = PuzzleBoard(
                boardMeasurementKey: _boardKey,
                puzzle: puzzle,
                pieces: provider.pieces,
                placedPositions: provider.placedPositions,
              );
              final tray = _PuzzleTray(
                provider: provider,
                draggingPieceId: _drag?.piece.id,
                onDragStart: _startDrag,
                onDragUpdate: _updateDrag,
                onDragEnd: _endDrag,
              );

              return Column(
                children: [
                  _GameHeader(provider: provider, onReset: _reset),
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
                        : 'Arrastrá una pieza cerca de su lugar.',
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
        ),
        if (_drag != null)
          AnimatedPositioned(
            key: Key('puzzle-dragging-piece-${_drag!.piece.id}'),
            left: _drag!.topLeft.dx,
            top: _drag!.topLeft.dy,
            width: _drag!.size.width,
            height: _drag!.size.height,
            duration: _drag!.isReturning ? _returnDuration : Duration.zero,
            curve: Curves.easeOutCubic,
            onEnd: _finishReturn,
            child: IgnorePointer(
              child: PuzzlePieceTile(
                piece: _drag!.piece,
                totalPieces: provider.pieces.length,
                expand: true,
              ),
            ),
          ),
      ],
    );
  }

  void _scheduleCompletionNavigation(BuildContext context) {
    if (!provider.isCompleted) {
      _completionNavigationScheduled = false;
      return;
    }
    if (_completionNavigationScheduled) {
      return;
    }

    _completionNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !provider.isCompleted) {
        return;
      }
      Navigator.pushNamed(context, AppRoutes.celebration);
    });
  }

  void _startDrag(PuzzlePiece piece, BuildContext pieceContext) {
    if (provider.isPlaced(piece.id) || provider.isCompleted) {
      return;
    }

    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final pieceBox = pieceContext.findRenderObject() as RenderBox?;
    if (stackBox == null || pieceBox == null) {
      return;
    }

    final pieceTopLeft = stackBox.globalToLocal(
      pieceBox.localToGlobal(Offset.zero),
    );
    final size = pieceBox.size;
    setState(() {
      _drag = _DragState(
        piece: piece,
        topLeft: pieceTopLeft,
        startTopLeft: pieceTopLeft,
        size: size,
        version: _gestureVersion,
      );
    });
  }

  void _updateDrag(DragUpdateDetails details) {
    final drag = _drag;
    if (drag == null || drag.isReturning || drag.version != _gestureVersion) {
      return;
    }

    setState(() {
      _drag = drag.copyWith(topLeft: drag.topLeft + details.delta);
    });
  }

  void _endDrag(DragEndDetails details) {
    final drag = _drag;
    if (drag == null || drag.version != _gestureVersion) {
      _clearDrag();
      return;
    }

    if (_isNearCorrectSlot(drag)) {
      _gestureVersion += 1;
      provider.placePiece(drag.piece.id);
      _clearDrag();
      return;
    }

    setState(() {
      _drag = drag.copyWith(topLeft: drag.startTopLeft, isReturning: true);
    });
  }

  bool _isNearCorrectSlot(_DragState drag) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || boardBox == null) {
      return false;
    }

    final boardTopLeft = stackBox.globalToLocal(
      boardBox.localToGlobal(Offset.zero),
    );
    final boardRect = boardTopLeft & boardBox.size;
    final dragCenter =
        drag.topLeft + Offset(drag.size.width / 2, drag.size.height / 2);
    if (!boardRect.contains(dragCenter)) {
      return false;
    }

    final grid = provider.currentPuzzle!.grid;
    final normalized = Offset(
      (dragCenter.dx - boardRect.left) / boardRect.width,
      (dragCenter.dy - boardRect.top) / boardRect.height,
    );
    final target = Offset(
      (drag.piece.correctPosition.column + 0.5) / grid.columns,
      (drag.piece.correctPosition.row + 0.5) / grid.rows,
    );

    return (normalized - target).distance <= _snapThreshold;
  }

  void _reset() {
    _gestureVersion += 1;
    _clearDrag();
    provider.reset();
  }

  void _finishReturn() {
    final drag = _drag;
    if (drag == null || !drag.isReturning || drag.version != _gestureVersion) {
      return;
    }
    _clearDrag();
  }

  void _clearDrag() {
    if (_drag == null) {
      return;
    }
    setState(() {
      _drag = null;
    });
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.provider, required this.onReset});

  final PuzzleGameProvider provider;
  final VoidCallback onReset;

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
          onPressed: onReset,
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
  const _PuzzleTray({
    required this.provider,
    required this.draggingPieceId,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final PuzzleGameProvider provider;
  final String? draggingPieceId;
  final void Function(PuzzlePiece piece, BuildContext context) onDragStart;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final void Function(DragEndDetails details) onDragEnd;

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
                Builder(
                  builder: (pieceContext) {
                    return GestureDetector(
                      onPanStart: (_) => onDragStart(piece, pieceContext),
                      onPanUpdate: onDragUpdate,
                      onPanEnd: onDragEnd,
                      child: Opacity(
                        opacity: draggingPieceId == piece.id ? 0 : 1,
                        child: PuzzlePieceTile(
                          key: Key('puzzle-piece-${piece.id}'),
                          piece: piece,
                          totalPieces: provider.pieces.length,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragState {
  const _DragState({
    required this.piece,
    required this.topLeft,
    required this.startTopLeft,
    required this.size,
    required this.version,
    this.isReturning = false,
  });

  final PuzzlePiece piece;
  final Offset topLeft;
  final Offset startTopLeft;
  final Size size;
  final int version;
  final bool isReturning;

  _DragState copyWith({Offset? topLeft, bool? isReturning}) {
    return _DragState(
      piece: piece,
      topLeft: topLeft ?? this.topLeft,
      startTopLeft: startTopLeft,
      size: size,
      version: version,
      isReturning: isReturning ?? this.isReturning,
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
