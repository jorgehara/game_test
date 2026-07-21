import 'grid_position.dart';
import 'normalized_rect.dart';

class PuzzlePiece {
  PuzzlePiece({
    required String id,
    required this.correctPosition,
    GridPosition? currentPosition,
    required this.crop,
  }) : id = _validateNotEmpty(id, 'id'),
       currentPosition = currentPosition ?? correctPosition {
    if (this.currentPosition.grid != correctPosition.grid) {
      throw ArgumentError.value(
        this.currentPosition,
        'currentPosition',
        'Must belong to the same grid as correctPosition',
      );
    }
  }

  final String id;
  final GridPosition correctPosition;
  final GridPosition currentPosition;
  final NormalizedRect crop;

  int get correctIndex => correctPosition.index;

  static void validateList(Iterable<PuzzlePiece> pieces) {
    final ids = <String>{};
    final positions = <GridPosition>{};

    for (final piece in pieces) {
      if (!ids.add(piece.id)) {
        throw ArgumentError.value(piece.id, 'pieces', 'Duplicate piece id');
      }
      if (!positions.add(piece.correctPosition)) {
        throw ArgumentError.value(
          piece.correctPosition,
          'pieces',
          'Duplicate correct position',
        );
      }
    }
  }

  static String _validateNotEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Must not be empty');
    }

    return value;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PuzzlePiece &&
            other.id == id &&
            other.correctPosition == correctPosition &&
            other.currentPosition == currentPosition &&
            other.crop == crop;
  }

  @override
  int get hashCode => Object.hash(id, correctPosition, currentPosition, crop);

  @override
  String toString() {
    return 'PuzzlePiece(id: $id, correctPosition: $correctPosition, currentPosition: $currentPosition, crop: $crop)';
  }
}
