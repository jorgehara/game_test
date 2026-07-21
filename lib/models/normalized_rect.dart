class NormalizedRect {
  NormalizedRect({
    required double left,
    required double top,
    required double width,
    required double height,
  }) : left = _validateOffset(left, 'left'),
       top = _validateOffset(top, 'top'),
       width = _validateSize(width, 'width'),
       height = _validateSize(height, 'height') {
    if (right > 1) {
      throw ArgumentError.value(right, 'right', 'Must not exceed 1');
    }
    if (bottom > 1) {
      throw ArgumentError.value(bottom, 'bottom', 'Must not exceed 1');
    }
  }

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;

  double get bottom => top + height;

  static double _validateOffset(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Must be finite');
    }
    if (value < 0 || value > 1) {
      throw ArgumentError.value(value, name, 'Must be between 0 and 1');
    }

    return value;
  }

  static double _validateSize(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Must be finite');
    }
    if (value <= 0 || value > 1) {
      throw ArgumentError.value(
        value,
        name,
        'Must be greater than 0 and at most 1',
      );
    }

    return value;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NormalizedRect &&
            other.left == left &&
            other.top == top &&
            other.width == width &&
            other.height == height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() {
    return 'NormalizedRect(left: $left, top: $top, width: $width, height: $height)';
  }
}
