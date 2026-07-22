enum PuzzleCategory {
  animals('animals', 'Animales'),
  vehicles('vehicles', 'Vehículos'),
  fruits('fruits', 'Frutas'),
  farm('farm', 'Granja'),
  dinosaurs('dinosaurs', 'Dinosaurios'),
  space('space', 'Espacio'),
  castles('castles', 'Castillos'),
  princesses('princesses', 'Princesas'),
  unicorns('unicorns', 'Unicornios'),
  ocean('ocean', 'Océano'),
  professions('professions', 'Profesiones');

  const PuzzleCategory(this.id, this.label);

  final String id;
  final String label;

  static PuzzleCategory fromId(String id) {
    for (final category in values) {
      if (category.id == id) {
        return category;
      }
    }

    throw ArgumentError.value(id, 'id', 'Unknown puzzle category');
  }
}
