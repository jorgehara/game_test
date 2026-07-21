class PuzzleDifficulty {
  PuzzleDifficulty.level(int level) : level = _validateLevel(level);

  final int level;

  int get targetPieceCount => switch (level) {
    1 => 2,
    2 => 4,
    3 => 6,
    4 => 9,
    5 => 12,
    _ => throw StateError('Invalid puzzle difficulty level: $level'),
  };

  static int _validateLevel(int level) {
    if (level < 1 || level > 5) {
      throw ArgumentError.value(level, 'level', 'Must be between 1 and 5');
    }

    return level;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PuzzleDifficulty && other.level == level;
  }

  @override
  int get hashCode => level.hashCode;

  @override
  String toString() => 'PuzzleDifficulty(level: $level)';
}
