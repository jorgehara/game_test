enum PuzzleCategory {
  animals('animals'),
  vehicles('vehicles'),
  fruits('fruits'),
  farm('farm'),
  dinosaurs('dinosaurs'),
  space('space');

  const PuzzleCategory(this.id);

  final String id;

  static PuzzleCategory fromId(String id) {
    for (final category in values) {
      if (category.id == id) {
        return category;
      }
    }

    throw ArgumentError.value(id, 'id', 'Unknown puzzle category');
  }
}
