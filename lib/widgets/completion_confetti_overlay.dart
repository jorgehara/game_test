import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/pk_tokens.dart';

class CompletionConfettiOverlay extends StatefulWidget {
  const CompletionConfettiOverlay({super.key});

  static const duration = Duration(milliseconds: 900);

  @override
  State<CompletionConfettiOverlay> createState() =>
      _CompletionConfettiOverlayState();
}

class _CompletionConfettiOverlayState extends State<CompletionConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CompletionConfettiOverlay.duration,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pkColors;
    final palette = colors.piecePalette;
    final disabled = MediaQuery.disableAnimationsOf(context);

    return Positioned.fill(
      key: const Key('completion-confetti-overlay'),
      child: IgnorePointer(
        child: Semantics(
          label: 'Celebración de puzzle completado',
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.10),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = disabled ? 1.0 : _controller.value;
                return Stack(
                  children: [
                    for (var index = 0; index < _pieces.length; index += 1)
                      _ConfettiPiece(
                        key: Key('completion-confetti-piece-$index'),
                        spec: _pieces[index],
                        color: palette[index % palette.length],
                        progress: progress,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPiece extends StatelessWidget {
  const _ConfettiPiece({
    super.key,
    required this.spec,
    required this.color,
    required this.progress,
  });

  final _ConfettiSpec spec;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress.clamp(0, 1));
    final fade = progress < 0.72
        ? 1.0
        : (1 - ((progress - 0.72) / 0.28)).clamp(0.0, 1.0);

    return Align(
      alignment: spec.alignment,
      child: Opacity(
        opacity: fade,
        child: Transform.translate(
          offset: Offset(spec.dx * eased, spec.dy * eased),
          child: Transform.rotate(
            angle: spec.rotation * math.pi * eased,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
              child: SizedBox(width: spec.width, height: spec.height),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiSpec {
  const _ConfettiSpec({
    required this.alignment,
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.width,
    required this.height,
  });

  final Alignment alignment;
  final double dx;
  final double dy;
  final double rotation;
  final double width;
  final double height;
}

const _pieces = [
  _ConfettiSpec(
    alignment: Alignment(-0.75, -0.70),
    dx: -36,
    dy: 96,
    rotation: -1.2,
    width: 8,
    height: 16,
  ),
  _ConfettiSpec(
    alignment: Alignment(-0.42, -0.82),
    dx: -18,
    dy: 112,
    rotation: 1.5,
    width: 12,
    height: 8,
  ),
  _ConfettiSpec(
    alignment: Alignment(-0.10, -0.76),
    dx: 8,
    dy: 104,
    rotation: -1.0,
    width: 9,
    height: 18,
  ),
  _ConfettiSpec(
    alignment: Alignment(0.22, -0.84),
    dx: 20,
    dy: 116,
    rotation: 1.3,
    width: 14,
    height: 8,
  ),
  _ConfettiSpec(
    alignment: Alignment(0.58, -0.72),
    dx: 34,
    dy: 98,
    rotation: -1.6,
    width: 8,
    height: 16,
  ),
  _ConfettiSpec(
    alignment: Alignment(0.82, -0.58),
    dx: 42,
    dy: 84,
    rotation: 1.0,
    width: 12,
    height: 10,
  ),
  _ConfettiSpec(
    alignment: Alignment(-0.88, -0.36),
    dx: -44,
    dy: 72,
    rotation: 1.8,
    width: 10,
    height: 14,
  ),
  _ConfettiSpec(
    alignment: Alignment(-0.56, -0.48),
    dx: -28,
    dy: 86,
    rotation: -1.4,
    width: 13,
    height: 8,
  ),
  _ConfettiSpec(
    alignment: Alignment(0.50, -0.46),
    dx: 28,
    dy: 88,
    rotation: 1.7,
    width: 9,
    height: 15,
  ),
  _ConfettiSpec(
    alignment: Alignment(0.88, -0.32),
    dx: 46,
    dy: 70,
    rotation: -1.1,
    width: 14,
    height: 8,
  ),
  _ConfettiSpec(
    alignment: Alignment(-0.22, -0.58),
    dx: -8,
    dy: 94,
    rotation: 1.2,
    width: 10,
    height: 16,
  ),
  _ConfettiSpec(
    alignment: Alignment(0.08, -0.62),
    dx: 10,
    dy: 96,
    rotation: -1.5,
    width: 12,
    height: 8,
  ),
];
