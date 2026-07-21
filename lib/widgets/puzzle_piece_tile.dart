import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';
import '../theme/pk_tokens.dart';

class PuzzlePieceTile extends StatelessWidget {
  const PuzzlePieceTile({
    super.key,
    required this.piece,
    required this.totalPieces,
    this.expand = false,
  });

  final PuzzlePiece piece;
  final int totalPieces;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final number = piece.correctIndex + 1;
    final colors = context.pkColors;

    return Semantics(
      label: 'Pieza $number de $totalPieces',
      child: Container(
        width: expand ? double.infinity : 86,
        height: expand ? double.infinity : 86,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors
              .piecePalette[piece.correctIndex % colors.piecePalette.length],
          border: Border.all(color: colors.onSurface, width: 3),
          borderRadius: BorderRadius.circular(context.pkRadius.button),
          boxShadow: [
            BoxShadow(
              color: colors.outline.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '$number',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
