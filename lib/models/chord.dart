class Chord {
  final String id;
  final String name;
  final String category;
  final List<int> fingering; // [0, 3, 2, 0, 1, 0] pro struny E-A-D-G-B-E
  final int position; // pozice na hmatníku (1 = první pražec)
  final bool hasBarre;
  final int? barreFret; // na kterém pražci je barre
  final String? description;
  final List<String> tags; // ["major", "open", "beginner"]
  final String difficulty; // "beginner", "intermediate", "advanced"

  const Chord({
    required this.id,
    required this.name,
    required this.category,
    required this.fingering,
    required this.position,
    this.hasBarre = false,
    this.barreFret,
    this.description,
    this.tags = const [],
    this.difficulty = "beginner",
  });

  factory Chord.fromMap(Map<String, dynamic> map, String id) {
    return Chord(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      fingering: List<int>.from(map['fingering'] ?? []),
      position: map['position'] ?? 1,
      hasBarre: map['hasBarre'] ?? false,
      barreFret: map['barreFret'],
      description: map['description'],
      tags: List<String>.from(map['tags'] ?? []),
      difficulty: map['difficulty'] ?? 'beginner',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'fingering': fingering,
      'position': position,
      'hasBarre': hasBarre,
      'barreFret': barreFret,
      'description': description,
      'tags': tags,
      'difficulty': difficulty,
    };
  }

  // Helper metody
  String get stringNames => 'E A D G B E';

  List<String> get stringNamesList => ['E', 'A', 'D', 'G', 'B', 'E'];

  // Vrátí pozici prstu pro danou strunu (0 = otevřená, -1 = neznělá)
  int getFingerPosition(int stringIndex) {
    if (stringIndex < 0 || stringIndex >= fingering.length) return -1;
    return fingering[stringIndex];
  }

  // Vrátí, jestli je struna znělá
  bool isStringPlayed(int stringIndex) {
    final position = getFingerPosition(stringIndex);
    return position > 0;
  }

  // Vrátí, jestli je struna otevřená
  bool isStringOpen(int stringIndex) {
    return getFingerPosition(stringIndex) == 0;
  }

  // Vrátí, jestli je struna neznělá
  bool isStringMuted(int stringIndex) {
    return getFingerPosition(stringIndex) == -1;
  }

  /// Vrací základní tón akordu (např. C, F#, Bb)
  String get root {
    final normalized = name.trim();
    if (normalized.isEmpty) return '';

    final match = RegExp(r'^[A-Ga-g](#|b)?').firstMatch(normalized);
    if (match != null) {
      return match.group(0)!.toUpperCase();
    }
    return normalized.substring(0, 1).toUpperCase();
  }
}
