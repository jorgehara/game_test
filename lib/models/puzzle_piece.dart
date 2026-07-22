import 'grid_position.dart';
import 'normalized_rect.dart';

enum PuzzlePieceEdge { flat, tab, blank }

extension PuzzlePieceEdgeComplement on PuzzlePieceEdge {
  PuzzlePieceEdge get complement {
    return switch (this) {
      PuzzlePieceEdge.flat => PuzzlePieceEdge.flat,
      PuzzlePieceEdge.tab => PuzzlePieceEdge.blank,
      PuzzlePieceEdge.blank => PuzzlePieceEdge.tab,
    };
  }
}

class PuzzlePieceEdges {
  const PuzzlePieceEdges({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  static const allFlat = PuzzlePieceEdges(
    top: PuzzlePieceEdge.flat,
    right: PuzzlePieceEdge.flat,
    bottom: PuzzlePieceEdge.flat,
    left: PuzzlePieceEdge.flat,
  );

  final PuzzlePieceEdge top;
  final PuzzlePieceEdge right;
  final PuzzlePieceEdge bottom;
  final PuzzlePieceEdge left;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PuzzlePieceEdges &&
            other.top == top &&
            other.right == right &&
            other.bottom == bottom &&
            other.left == left;
  }

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  String toString() {
    return 'PuzzlePieceEdges(top: $top, right: $right, bottom: $bottom, left: $left)';
  }
}

class PuzzlePiece {
  PuzzlePiece({
    required String id,
    required this.correctPosition,
    GridPosition? currentPosition,
    this.edges = PuzzlePieceEdges.allFlat,
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
  final PuzzlePieceEdges edges;
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
            other.edges == edges &&
            other.crop == crop;
  }

  @override
  int get hashCode {
    return Object.hash(id, correctPosition, currentPosition, edges, crop);
  }

  @override
  String toString() {
    return 'PuzzlePiece(id: $id, correctPosition: $correctPosition, currentPosition: $currentPosition, edges: $edges, crop: $crop)';
  }
}
