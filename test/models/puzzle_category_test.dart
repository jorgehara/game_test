import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/puzzle_category.dart';

void main() {
  group('PuzzleCategory', () {
    test('contains preschool and fantasy categories with stable ids', () {
      expect(
        PuzzleCategory.values.map((category) => category.id),
        equals([
          'animals',
          'vehicles',
          'fruits',
          'farm',
          'dinosaurs',
          'space',
          'castles',
          'princesses',
          'unicorns',
          'ocean',
          'professions',
        ]),
      );
      expect(PuzzleCategory.castles.label, 'Castillos');
      expect(PuzzleCategory.princesses.label, 'Princesas');
      expect(PuzzleCategory.unicorns.label, 'Unicornios');
      expect(PuzzleCategory.professions.label, 'Profesiones');
    });

    test('parses known category ids', () {
      expect(PuzzleCategory.fromId('animals'), PuzzleCategory.animals);
      expect(PuzzleCategory.fromId('space'), PuzzleCategory.space);
      expect(PuzzleCategory.fromId('professions'), PuzzleCategory.professions);
    });

    test('rejects unknown category ids', () {
      expect(() => PuzzleCategory.fromId('unknown'), throwsArgumentError);
      expect(() => PuzzleCategory.fromId(''), throwsArgumentError);
    });
  });
}
