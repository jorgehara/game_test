import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';

void main() {
  group('PuzzleCategory', () {
    test('contains the six PRD categories with stable ids', () {
      expect(
        PuzzleCategory.values.map((category) => category.id),
        equals(['animals', 'vehicles', 'fruits', 'farm', 'dinosaurs', 'space']),
      );
    });

    test('parses known category ids', () {
      expect(PuzzleCategory.fromId('animals'), PuzzleCategory.animals);
      expect(PuzzleCategory.fromId('space'), PuzzleCategory.space);
    });

    test('rejects unknown category ids', () {
      expect(() => PuzzleCategory.fromId('unknown'), throwsArgumentError);
      expect(() => PuzzleCategory.fromId(''), throwsArgumentError);
    });
  });
}
