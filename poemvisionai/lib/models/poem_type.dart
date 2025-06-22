class PoemType {
  final String id;
  final String name;
  final String? category;
  final bool free;

  const PoemType({
    required this.id,
    required this.name,
    this.category,
    required this.free,
  });

  factory PoemType.fromJson(Map<String, dynamic> json) {
    return PoemType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'],
      free: json['free'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'free': free,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PoemType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PoemTypeData {
  static const List<PoemType> allPoemTypes = [
    // Standard poems
    PoemType(id: "general verse", name: "General Verse", free: true),
    PoemType(id: "love", name: "Romantic/Love Poem", free: true),
    PoemType(id: "funny", name: "Funny/Humorous", free: true),
    PoemType(id: "inspirational", name: "Inspirational/Motivational", free: true),
    PoemType(id: "angry", name: "Angry/Intense", free: false),
    PoemType(id: "extreme", name: "Extreme/Bold", free: false),
    PoemType(id: "holiday", name: "Holiday", free: false),
    PoemType(id: "birthday", name: "Birthday", free: false),
    PoemType(id: "anniversary", name: "Anniversary", free: false),
    PoemType(id: "nature", name: "Nature", free: false),
    PoemType(id: "friendship", name: "Friendship", free: false),

    // Life events
    PoemType(id: "memorial", name: "In Memory/RIP", free: false),
    PoemType(id: "farewell", name: "Farewell/Goodbye", free: false),
    PoemType(id: "newborn", name: "Newborn/Baby", free: false),

    // Religious
    PoemType(id: "religious-islam", name: "Islamic/Muslim", free: false),
    PoemType(id: "religious-christian", name: "Christian", free: false),
    PoemType(id: "religious-judaism", name: "Jewish/Judaism", free: false),
    PoemType(id: "religious-general", name: "Spiritual/General", free: false),

    // Famous Poets
    PoemType(id: "william-shakespeare", name: "William Shakespeare", category: "famousPoets", free: false),
    PoemType(id: "emily-dickinson", name: "Emily Dickinson", category: "famousPoets", free: false),
    PoemType(id: "dante-alighieri", name: "Dante Alighieri", category: "famousPoets", free: false),
    PoemType(id: "maya-angelou", name: "Maya Angelou", category: "famousPoets", free: false),
    PoemType(id: "robert-frost", name: "Robert Frost", category: "famousPoets", free: false),
    PoemType(id: "rumi", name: "Rumi", category: "famousPoets", free: false),
    PoemType(id: "langston-hughes", name: "Langston Hughes", category: "famousPoets", free: false),
    PoemType(id: "sylvia-plath", name: "Sylvia Plath", category: "famousPoets", free: false),
    PoemType(id: "pablo-neruda", name: "Pablo Neruda", category: "famousPoets", free: false),
    PoemType(id: "walt-whitman", name: "Walt Whitman", category: "famousPoets", free: false),
    PoemType(id: "edgar-allan-poe", name: "Edgar Allan Poe", category: "famousPoets", free: false),

    // Flirty fun
    PoemType(id: "pick-up", name: "Pick-Up Lines", free: false),
    PoemType(id: "roast-you", name: "Roast You", free: false),
    PoemType(id: "first-date-feel", name: "First Date Feel", free: false),
    PoemType(id: "love-at-first-sight", name: "Love at First Sight", free: false),

    // Congratulations Category
    PoemType(id: "graduation", name: "Graduation", category: "congratulations", free: false),
    PoemType(id: "new-job", name: "New Job", free: false),
    PoemType(id: "wedding", name: "Wedding", free: false),
    PoemType(id: "engagement", name: "Engagement", free: false),
    PoemType(id: "new-baby", name: "New Baby", free: false),
    PoemType(id: "promotion", name: "Promotion", free: false),
    PoemType(id: "new-home", name: "New Home", free: false),
    PoemType(id: "new-car", name: "New Car", free: false),
    PoemType(id: "new-pet", name: "New Pet", free: false),
    PoemType(id: "first-day-of-school", name: "First Day of School", free: false),
    PoemType(id: "retirement", name: "Retirement", free: false),

    // Holidays
    PoemType(id: "new-year", name: "New Year", free: false),
    PoemType(id: "valentines-day", name: "Valentines Day", free: false),
    PoemType(id: "ramadan", name: "Ramadan", free: false),
    PoemType(id: "halloween", name: "Halloween", free: false),
    PoemType(id: "easter", name: "Easter", free: false),
    PoemType(id: "thanksgiving", name: "Thanksgiving", free: false),
    PoemType(id: "mother-day", name: "Mother Day", free: false),
    PoemType(id: "father-day", name: "Father Day", free: false),
    PoemType(id: "christmas", name: "Christmas", free: false),
    PoemType(id: "independence-day", name: "Independence Day", free: false),
    PoemType(id: "hanukkah", name: "Hanukkah", free: false),
    PoemType(id: "diwali", name: "Diwali", free: false),
    PoemType(id: "new-year-eve", name: "New Year Eve", free: false),

    // Fun formats
    PoemType(id: "twinkle", name: "Twinkle Twinkle", free: false),
    PoemType(id: "roses", name: "Roses are Red", free: false),
    PoemType(id: "knock-knock", name: "Knock Knock", free: false),
    PoemType(id: "hickory dickory dock", name: "Hickory Dickory Dock", free: false),
    PoemType(id: "nursery-rhymes", name: "Nursery Rhymes", free: false),

    // Music
    PoemType(id: "rap/hiphop", name: "Rap/Hip-Hop", free: false),
    PoemType(id: "country", name: "Country", free: false),
    PoemType(id: "rock", name: "Rock", free: false),
    PoemType(id: "jazz", name: "Jazz", free: false),
    PoemType(id: "pop", name: "Pop", free: false),

    // Artists
    PoemType(id: "eminem", name: "Eminem", free: false),
    PoemType(id: "kendrick-lamar", name: "Kendrick Lamar", free: false),
    PoemType(id: "taylor-swift", name: "Taylor Swift", free: false),
    PoemType(id: "drake", name: "Drake", free: false),
    PoemType(id: "50cent", name: "50 Cent", free: false),
    PoemType(id: "lil-wayne", name: "Lil Wayne", free: false),
    PoemType(id: "doja-cat", name: "Doja Cat", free: false),
    PoemType(id: "nicki-minaj", name: "Nicki Minaj", free: false),
    PoemType(id: "j. cole", name: "J. Cole", free: false),
    PoemType(id: "elvis-presley", name: "Elvis Presley", free: false),
    PoemType(id: "tupac", name: "Tupac Shakur", free: false),
    PoemType(id: "biggie-smalls", name: "Biggie Smalls", free: false),
    PoemType(id: "buddy-holly", name: "Buddy Holly", free: false),
    PoemType(id: "luis-armstrong", name: "Luis Armstrong", free: false),

    // Classical forms
    PoemType(id: "haiku", name: "Haiku", free: false),
    PoemType(id: "limerick", name: "Limerick", free: false),
    PoemType(id: "tanka", name: "Tanka", free: false),
    PoemType(id: "senryu", name: "Senryu", free: false),

    // Tribulations
    PoemType(id: "get-well-soon", name: "Get Well Soon", free: false),
    PoemType(id: "apology", name: "Apology/Sorry", free: false),
    PoemType(id: "divorce", name: "Divorce/Breakup", free: false),
    PoemType(id: "hard-times", name: "Hard Times/Struggles", free: false),
    PoemType(id: "missing-you", name: "Missing You", free: false),
    PoemType(id: "conflict", name: "Conflict/Disagreement", free: false),
    PoemType(id: "lost-pet", name: "Lost Pet", free: false),
  ];

  static List<PoemType> getAvailablePoemTypes({bool isPremium = false}) {
    if (isPremium) {
      return allPoemTypes;
    } else {
      return allPoemTypes.where((poemType) => poemType.free).toList();
    }
  }

  static List<PoemType> getFreePoemTypes() {
    return allPoemTypes.where((poemType) => poemType.free).toList();
  }

  static List<PoemType> getPremiumPoemTypes() {
    return allPoemTypes.where((poemType) => !poemType.free).toList();
  }

  static Map<String, List<PoemType>> getPoemTypesByCategory({bool isPremium = false}) {
    final availableTypes = getAvailablePoemTypes(isPremium: isPremium);
    final Map<String, List<PoemType>> categorized = {};

    for (final poemType in availableTypes) {
      final category = poemType.category ?? 'General';
      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }
      categorized[category]!.add(poemType);
    }

    return categorized;
  }

  static PoemType? findById(String id) {
    try {
      return allPoemTypes.firstWhere((poemType) => poemType.id == id);
    } catch (e) {
      return null;
    }
  }
}
