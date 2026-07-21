import 'package:flutter/material.dart';

import '../models/puzzle_piece.dart';

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

    return Semantics(
      label: 'Pieza $number de $totalPieces',
      child: Container(
        width: expand ? double.infinity : 86,
        height: expand ? double.infinity : 86,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _pieceColor(piece.correctIndex),
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Color _pieceColor(int index) {
    const colors = [
      Color(0xFFFFC857),
      Color(0xFF8BE28B),
      Color(0xFF78D6FF),
      Color(0xFFFF8FB3),
      Color(0xFFD6B4FF),
      Color(0xFFFFA45B),
      Color(0xFFA6F0E4),
      Color(0xFFFFF27A),
      Color(0xFFB8E986),
    ];

    return colors[index % colors.length];
  }
}
