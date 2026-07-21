import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/models/normalized_rect.dart';

void main() {
  group('NormalizedRect', () {
    test('accepts crop rectangles inside the unit square', () {
      final rect = NormalizedRect(
        left: 0.5,
        top: 0.25,
        width: 0.5,
        height: 0.75,
      );

      expect(rect.right, 1);
      expect(rect.bottom, 1);
    });

    test('rejects negative offsets or sizes', () {
      expect(
        () => NormalizedRect(left: -0.1, top: 0, width: 0.5, height: 0.5),
        throwsArgumentError,
      );
      expect(
        () => NormalizedRect(left: 0, top: -0.1, width: 0.5, height: 0.5),
        throwsArgumentError,
      );
      expect(
        () => NormalizedRect(left: 0, top: 0, width: 0, height: 0.5),
        throwsArgumentError,
      );
      expect(
        () => NormalizedRect(left: 0, top: 0, width: 0.5, height: 0),
        throwsArgumentError,
      );
    });

    test('rejects rectangles that exceed the unit square', () {
      expect(
        () => NormalizedRect(left: 0.6, top: 0, width: 0.5, height: 0.5),
        throwsArgumentError,
      );
      expect(
        () => NormalizedRect(left: 0, top: 0.6, width: 0.5, height: 0.5),
        throwsArgumentError,
      );
    });

    test('rejects non-finite coordinates and sizes', () {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => NormalizedRect(left: value, top: 0, width: 0.5, height: 0.5),
          throwsArgumentError,
        );
        expect(
          () => NormalizedRect(left: 0, top: value, width: 0.5, height: 0.5),
          throwsArgumentError,
        );
        expect(
          () => NormalizedRect(left: 0, top: 0, width: value, height: 0.5),
          throwsArgumentError,
        );
        expect(
          () => NormalizedRect(left: 0, top: 0, width: 0.5, height: value),
          throwsArgumentError,
        );
      }
    });

    test('rejects width or height above one directly', () {
      expect(
        () => NormalizedRect(left: 0, top: 0, width: 1.1, height: 0.5),
        throwsArgumentError,
      );
      expect(
        () => NormalizedRect(left: 0, top: 0, width: 0.5, height: 1.1),
        throwsArgumentError,
      );
    });

    test('is equality-friendly by normalized coordinates', () {
      expect(
        NormalizedRect(left: 0, top: 0, width: 0.5, height: 0.5),
        NormalizedRect(left: 0, top: 0, width: 0.5, height: 0.5),
      );
    });

    test('uses coordinate values for hashCode and toString', () {
      final rect = NormalizedRect(left: 0, top: 0.25, width: 0.5, height: 0.75);
      final same = NormalizedRect(left: 0, top: 0.25, width: 0.5, height: 0.75);

      expect(rect.hashCode, same.hashCode);
      expect(
        rect.toString(),
        'NormalizedRect(left: 0.0, top: 0.25, width: 0.5, height: 0.75)',
      );
    });
  });
}
