import 'dart:math';

import '../models/puzzle_piece.dart';

class PuzzleShuffler {
  const PuzzleShuffler._();

  static List<PuzzlePiece> shuffle(
    List<PuzzlePiece> pieces, {
    required int seed,
  }) {
    final shuffled = List<PuzzlePiece>.of(pieces)..shuffle(Random(seed));

    if (_canAvoidSolvedOrder(shuffled) && _isSolvedOrder(shuffled)) {
      final first = shuffled.removeAt(0);
      shuffled.add(first);
    }

    return List.unmodifiable(shuffled);
  }

  static bool _canAvoidSolvedOrder(List<PuzzlePiece> pieces) {
    return pieces.length > 1;
  }

  static bool _isSolvedOrder(List<PuzzlePiece> pieces) {
    for (var index = 0; index < pieces.length; index++) {
      if (pieces[index].correctIndex != index) {
        return false;
      }
    }

    return true;
  }
}
