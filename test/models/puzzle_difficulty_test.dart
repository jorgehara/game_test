import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/puzzle_difficulty.dart';

void main() {
  group('PuzzleDifficulty', () {
    test('maps PRD levels 1 through 5 to target piece counts', () {
      expect(PuzzleDifficulty.level(1).targetPieceCount, 2);
      expect(PuzzleDifficulty.level(2).targetPieceCount, 4);
      expect(PuzzleDifficulty.level(3).targetPieceCount, 6);
      expect(PuzzleDifficulty.level(4).targetPieceCount, 9);
      expect(PuzzleDifficulty.level(5).targetPieceCount, 12);
    });

    test('rejects levels outside 1 through 5', () {
      expect(() => PuzzleDifficulty.level(0), throwsArgumentError);
      expect(() => PuzzleDifficulty.level(6), throwsArgumentError);
    });

    test('is equality-friendly by level', () {
      expect(PuzzleDifficulty.level(3), PuzzleDifficulty.level(3));
      expect(
        PuzzleDifficulty.level(3).hashCode,
        PuzzleDifficulty.level(3).hashCode,
      );
    });
  });
}
