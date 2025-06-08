/// Model representing a poem type
class PoemType {
  final String id;
  final String name;
  final String description;
  final bool isPremium;
  final List<String> examples;

  const PoemType({
    required this.id,
    required this.name,
    required this.description,
    this.isPremium = false,
    this.examples = const [],
  });

  /// Factory constructor to create a PoemType from JSON
  factory PoemType.fromJson(Map<String, dynamic> json) {
    return PoemType(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      examples: (json['examples'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
    );
  }

  /// Convert PoemType to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_premium': isPremium,
      'examples': examples,
    };
  }
}

/// Predefined poem types
class PoemTypes {
  static const PoemType generalVerse = PoemType(
    id: 'general_verse',
    name: 'General',
    description: 'A versatile poem that adapts to any subject matter',
    isPremium: false,
  );

  static const PoemType haiku = PoemType(
    id: 'haiku',
    name: 'Haiku',
    description: 'Traditional Japanese poem with 5-7-5 syllable pattern',
    isPremium: false,
  );

  static const PoemType sonnet = PoemType(
    id: 'sonnet',
    name: 'Sonnet',
    description: 'Fourteen-line poem with a specific rhyme scheme',
    isPremium: true,
  );

  static const PoemType freeVerse = PoemType(
    id: 'free_verse',
    name: 'Free Verse',
    description: 'Poetry without regular patterns of rhyme or meter',
    isPremium: false,
  );

  static const PoemType limerick = PoemType(
    id: 'limerick',
    name: 'Limerick',
    description: 'Five-line poem with an AABBA rhyme scheme, often humorous',
    isPremium: true,
  );

  static const PoemType acrostic = PoemType(
    id: 'acrostic',
    name: 'Acrostic',
    description: 'Poem where the first letter of each line spells a word',
    isPremium: true,
  );

  static const PoemType ode = PoemType(
    id: 'ode',
    name: 'Ode',
    description: 'Formal poem expressing praise or tribute',
    isPremium: true,
  );

  static const PoemType narrative = PoemType(
    id: 'narrative',
    name: 'Narrative',
    description: 'Tells a story with plot, characters, and setting',
    isPremium: false,
  );

  /// Get all available poem types
  static List<PoemType> getAll() {
    return [
      generalVerse,
      haiku,
      sonnet,
      freeVerse,
      limerick,
      acrostic,
      ode,
      narrative,
    ];
  }

  /// Get free poem types only
  static List<PoemType> getFree() {
    return getAll().where((type) => !type.isPremium).toList();
  }

  /// Get premium poem types only
  static List<PoemType> getPremium() {
    return getAll().where((type) => type.isPremium).toList();
  }

  /// Get a poem type by ID
  static PoemType? getById(String id) {
    try {
      return getAll().firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }
}
