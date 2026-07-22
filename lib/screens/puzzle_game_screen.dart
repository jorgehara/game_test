import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/puzzle.dart';
import '../models/puzzle_piece.dart';
import '../providers/onboarding_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/puzzle_game_provider.dart';
import '../routes/app_routes.dart';
import '../services/asset_manifest_validator.dart';
import '../services/puzzle_asset_manifest_loader.dart';
import '../services/puzzle_catalog_service.dart';
import '../theme/pk_tokens.dart';
import '../widgets/completion_confetti_overlay.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/pk_button.dart';
import '../widgets/pk_progress.dart';
import '../widgets/pk_scaffold.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/puzzle_piece_geometry.dart';
import '../widgets/puzzle_piece_tile.dart';

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({
    super.key,
    this.assetManifest,
    this.existingAssetPaths = const {},
    this.assetBundle,
  });

  final List<AssetManifestEntry>? assetManifest;
  final Set<String> existingAssetPaths;
  final AssetBundle? assetBundle;

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
    return PkScaffold(
      title: 'Juego',
      child: Consumer<PuzzleGameProvider>(
        builder: (context, provider, _) {
          if (provider.status == PuzzleGameStatus.unavailable ||
              provider.currentPuzzle == null) {
            return _UnavailableGame(onBack: () => Navigator.maybePop(context));
          }

          return _ReadyGame(
            provider: provider,
            assetManifest: widget.assetManifest,
            existingAssetPaths: widget.existingAssetPaths,
            assetBundle: widget.assetBundle,
          );
        },
      ),
    );
  }
}

class _ReadyGame extends StatefulWidget {
  const _ReadyGame({
    required this.provider,
    required this.assetManifest,
    required this.existingAssetPaths,
    required this.assetBundle,
  });

  final PuzzleGameProvider provider;
  final List<AssetManifestEntry>? assetManifest;
  final Set<String> existingAssetPaths;
  final AssetBundle? assetBundle;

  @override
  State<_ReadyGame> createState() => _ReadyGameState();
}

class _ReadyGameState extends State<_ReadyGame> {
  static const _snapThreshold = 0.10;
  static const _returnDuration = Duration(milliseconds: 300);
  static const _wideTrayWidth = 280.0;
  static const _completedTrayHeight = 104.0;
  static const _narrowTrayHeight = 148.0;

  final _stackKey = GlobalKey();
  final _boardKey = GlobalKey();
  late Future<List<AssetManifestEntry>> _assetManifestFuture;
  List<AssetManifestEntry>? _resolvedAssetManifest;
  _DragState? _drag;
  var _gestureVersion = 0;
  var _completionToken = 0;
  var _completionPhase = _CompletionPhase.idle;
  String? _completionDialogPuzzleId;
  var _completionDialogOpen = false;
  var _onboardingDialogOpen = false;

  PuzzleGameProvider get provider => widget.provider;

  @override
  void initState() {
    super.initState();
    _assetManifestFuture = _loadAssetManifest();
  }

  @override
  void didUpdateWidget(covariant _ReadyGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetManifest != widget.assetManifest ||
        oldWidget.assetBundle != widget.assetBundle) {
      _resolvedAssetManifest = null;
      _assetManifestFuture = _loadAssetManifest();
    }
  }

  @override
  void dispose() {
    _completionToken += 1;
    super.dispose();
  }

  Future<List<AssetManifestEntry>> _loadAssetManifest() {
    return widget.assetManifest == null
        ? PuzzleAssetManifestLoader.loadApproved(bundle: widget.assetBundle)
        : Future.value(widget.assetManifest);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleDragOnboarding(context);
    _scheduleCompletionCelebration(context);

    final puzzle = provider.currentPuzzle!;
    final total = provider.pieces.length;
    final spacing = context.pkSpacing;

    return FutureBuilder<List<AssetManifestEntry>>(
      future: _assetManifestFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _resolvedAssetManifest = snapshot.data;
        }
        final pieceImageSource = _pieceImageSourceFor(
          puzzle,
          snapshot.data ?? _resolvedAssetManifest,
        );

        return Stack(
          key: _stackKey,
          children: [
            Padding(
              key: const Key('puzzle-game-screen'),
              padding: EdgeInsets.all(spacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 780;
                  final board = PuzzleBoard(
                    boardMeasurementKey: _boardKey,
                    puzzle: puzzle,
                    pieces: provider.pieces,
                    placedPositions: provider.placedPositions,
                    pieceImageSource: pieceImageSource,
                  );
                  final tray = provider.isCompleted
                      ? const _CompletedPuzzleTray()
                      : _PuzzleTray(
                          provider: provider,
                          pieceImageSource: pieceImageSource,
                          draggingPieceId: _drag?.piece.id,
                          onDragStart: (piece, context) =>
                              _startDrag(piece, context, pieceImageSource),
                          onDragUpdate: _updateDrag,
                          onDragEnd: _endDrag,
                        );

                  return Column(
                    children: [
                      _GameHeader(provider: provider, onReset: _reset),
                      SizedBox(height: spacing.md),
                      Expanded(
                        child: isWide
                            ? provider.isCompleted
                                  ? Column(
                                      children: [
                                        Expanded(child: board),
                                        SizedBox(height: spacing.md),
                                        SizedBox(
                                          width: double.infinity,
                                          height: _completedTrayHeight,
                                          child: tray,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(flex: 3, child: board),
                                        SizedBox(width: spacing.lg),
                                        SizedBox(
                                          width: _wideTrayWidth,
                                          child: tray,
                                        ),
                                      ],
                                    )
                            : Column(
                                children: [
                                  Expanded(child: board),
                                  SizedBox(height: spacing.md),
                                  SizedBox(
                                    width: double.infinity,
                                    height: _narrowTrayHeight,
                                    child: tray,
                                  ),
                                ],
                              ),
                      ),
                      SizedBox(height: spacing.sm),
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
                        child: Text(
                          'Progreso ${provider.progressCount}/$total',
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      PkProgress(
                        value: total == 0 ? 0 : provider.progressCount / total,
                        label: 'Progreso del puzzle',
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
                duration: _drag!.isReturning
                    ? context.pkMotion.resolve(context, _returnDuration)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                onEnd: _finishReturn,
                child: IgnorePointer(
                  child: PuzzlePieceTile(
                    piece: _drag!.piece,
                    totalPieces: provider.pieces.length,
                    imageSource: _drag!.imageSource,
                    geometry: PuzzlePieceGeometry.forDrag(
                      piece: _drag!.piece,
                      size: _drag!.size,
                    ),
                    expand: true,
                  ),
                ),
              ),
            if (_completionPhase == _CompletionPhase.celebrating)
              const CompletionConfettiOverlay(),
          ],
        );
      },
    );
  }

  PuzzlePieceImageSource? _pieceImageSourceFor(
    Puzzle puzzle,
    List<AssetManifestEntry>? manifest,
  ) {
    if (manifest == null) return null;

    final approvedAsset = PuzzleCatalogService.approvedAssetFor(
      puzzle,
      manifest,
      existingAssetPaths: widget.existingAssetPaths.isEmpty
          ? PuzzleAssetManifestLoader.existingPathsFor(manifest)
          : widget.existingAssetPaths,
    );
    if (approvedAsset == null) return null;

    return PuzzlePieceImageSource(
      assetPath: approvedAsset.path,
      sourceWidth: approvedAsset.width,
      sourceHeight: approvedAsset.height,
    );
  }

  void _scheduleDragOnboarding(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    if (!onboarding.shouldShowDragOnboarding || _onboardingDialogOpen) {
      return;
    }

    _onboardingDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !onboarding.shouldShowDragOnboarding) {
        _onboardingDialogOpen = false;
        return;
      }

      await showDialog<void>(
        context: this.context,
        barrierDismissible: false,
        builder: (dialogContext) => _DragOnboardingDialog(
          onDismiss: () async {
            await onboarding.completeDragOnboarding();
          },
        ),
      );

      if (mounted) {
        setState(() {
          _onboardingDialogOpen = false;
          if (_completionPhase == _CompletionPhase.dialogPending) {
            _completionPhase = _CompletionPhase.idle;
          }
        });
      }
    });
  }

  void _scheduleCompletionCelebration(BuildContext context) {
    if (!provider.isCompleted) {
      _cancelCompletionCelebration();
      return;
    }
    final puzzle = provider.currentPuzzle;
    if (puzzle == null ||
        _completionDialogOpen ||
        _completionPhase != _CompletionPhase.idle ||
        _completionDialogPuzzleId == puzzle.id) {
      return;
    }

    final token = ++_completionToken;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    _completionPhase = reducedMotion
        ? _CompletionPhase.dialogPending
        : _CompletionPhase.celebrating;
    unawaited(_runCompletionSequence(puzzle, token, reducedMotion));
  }

  Future<void> _runCompletionSequence(
    Puzzle puzzle,
    int token,
    bool reducedMotion,
  ) async {
    await Future<void>.delayed(
      reducedMotion
          ? const Duration(milliseconds: 16)
          : CompletionConfettiOverlay.duration,
    );
    if (!_isCompletionTokenCurrent(token, puzzle.id)) {
      return;
    }

    if (!mounted) return;
    await context.read<ProgressProvider>().markCompleted(puzzle.id);
    if (!_isCompletionTokenCurrent(token, puzzle.id)) {
      return;
    }
    if (!_canShowCompletionDialog()) {
      if (mounted) {
        setState(() => _completionPhase = _CompletionPhase.dialogPending);
      }
      return;
    }

    setState(() {
      _completionDialogOpen = true;
      _completionDialogPuzzleId = puzzle.id;
      _completionPhase = _CompletionPhase.dialogShown;
    });

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CompletionDialog(
        puzzleName: puzzle.name,
        onReplay: () {
          Navigator.of(dialogContext).maybePop();
          _reset();
        },
        onContinue: () {
          Navigator.of(dialogContext).maybePop();
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.selection,
            ModalRoute.withName(AppRoutes.menu),
          );
        },
      ),
    );

    if (mounted && _completionToken == token) {
      setState(() => _completionDialogOpen = false);
    }
  }

  bool _isCompletionTokenCurrent(int token, String puzzleId) {
    return mounted &&
        _completionToken == token &&
        provider.isCompleted &&
        provider.currentPuzzle?.id == puzzleId;
  }

  bool _canShowCompletionDialog() {
    return mounted &&
        !_onboardingDialogOpen &&
        !_completionDialogOpen &&
        (ModalRoute.of(context)?.isCurrent ?? true);
  }

  void _cancelCompletionCelebration() {
    if (_completionPhase == _CompletionPhase.idle &&
        !_completionDialogOpen &&
        _completionDialogPuzzleId == null) {
      return;
    }

    _completionToken += 1;
    _completionPhase = _CompletionPhase.idle;
    _completionDialogOpen = false;
    _completionDialogPuzzleId = null;
  }

  void _startDrag(
    PuzzlePiece piece,
    BuildContext pieceContext,
    PuzzlePieceImageSource? pieceImageSource,
  ) {
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
        imageSource: pieceImageSource,
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
    _cancelCompletionCelebration();
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

enum _CompletionPhase { idle, celebrating, dialogPending, dialogShown }

class _DragOnboardingDialog extends StatelessWidget {
  const _DragOnboardingDialog({required this.onDismiss});

  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(onDismiss());
        }
      },
      child: AlertDialog(
        key: const Key('drag-onboarding-dialog'),
        icon: Icon(
          Icons.touch_app_rounded,
          color: context.pkColors.primary,
          semanticLabel: 'Tutorial de arrastrar piezas',
        ),
        title: const Text('Arrastrá y soltá'),
        content: const Text(
          'Tocá una pieza, arrastrala hasta su lugar y soltala cerca del dibujo.',
        ),
        actions: [
          TextButton(
            onPressed: () => _dismiss(context),
            child: const Text('Omitir'),
          ),
          PkButton(
            label: 'Entendido',
            icon: Icons.check_rounded,
            onPressed: () => _dismiss(context),
          ),
        ],
      ),
    );
  }

  Future<void> _dismiss(BuildContext context) async {
    await onDismiss();
    if (context.mounted) {
      Navigator.of(context).maybePop();
    }
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.provider, required this.onReset});

  final PuzzleGameProvider provider;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.pkSpacing.sm,
      runSpacing: context.pkSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        _LargeControl(
          key: const Key('puzzle-back-button'),
          label: 'Volver',
          icon: Icons.arrow_back_rounded,
          variant: PkButtonVariant.ghost,
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
          variant: PkButtonVariant.tonal,
          onPressed: onReset,
        ),
        _LargeControl(
          key: const Key('puzzle-sound-placeholder-button'),
          label: 'Sonido pronto',
          icon: Icons.volume_off_rounded,
          variant: PkButtonVariant.ghost,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _PuzzleTray extends StatelessWidget {
  const _PuzzleTray({
    required this.provider,
    required this.pieceImageSource,
    required this.draggingPieceId,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final PuzzleGameProvider provider;
  final PuzzlePieceImageSource? pieceImageSource;
  final String? draggingPieceId;
  final void Function(PuzzlePiece piece, BuildContext context) onDragStart;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final void Function(DragEndDetails details) onDragEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.pkColors;
    final spacing = context.pkSpacing;
    return Semantics(
      label: 'Bandeja de piezas',
      child: SizedBox.expand(
        child: DecoratedBox(
          key: const Key('puzzle-tray'),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.64),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(context.pkRadius.card),
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.sm),
            child: Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
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
                            imageSource: pieceImageSource,
                            geometry: PuzzlePieceGeometry.forTray(piece: piece),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedPuzzleTray extends StatelessWidget {
  const _CompletedPuzzleTray();

  @override
  Widget build(BuildContext context) {
    final colors = context.pkColors;
    final spacing = context.pkSpacing;

    return Semantics(
      label: 'Bandeja completa sin piezas pendientes',
      child: SizedBox.expand(
        key: const Key('puzzle-tray-complete'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceAlt.withValues(alpha: 0.72),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.32),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(context.pkRadius.card),
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Center(
              child: Text(
                'Todas las piezas están en el tablero',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DragState {
  const _DragState({
    required this.piece,
    required this.imageSource,
    required this.topLeft,
    required this.startTopLeft,
    required this.size,
    required this.version,
    this.isReturning = false,
  });

  final PuzzlePiece piece;
  final PuzzlePieceImageSource? imageSource;
  final Offset topLeft;
  final Offset startTopLeft;
  final Size size;
  final int version;
  final bool isReturning;

  _DragState copyWith({Offset? topLeft, bool? isReturning}) {
    return _DragState(
      piece: piece,
      imageSource: imageSource,
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
    required this.variant,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final PkButtonVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PkButton(
        label: label,
        icon: icon,
        variant: variant,
        semanticLabel: label,
        onPressed: onPressed,
      ),
    );
  }
}

class _UnavailableGame extends StatelessWidget {
  const _UnavailableGame({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final spacing = context.pkSpacing;
    return Center(
      key: const Key('puzzle-unavailable-state'),
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Puzzle no disponible',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: spacing.md),
            const Text(
              'Este puzzle todavía no está listo. Probemos con otro.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.lg),
            _LargeControl(
              key: const Key('puzzle-back-button'),
              label: 'Volver',
              icon: Icons.arrow_back_rounded,
              variant: PkButtonVariant.ghost,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
