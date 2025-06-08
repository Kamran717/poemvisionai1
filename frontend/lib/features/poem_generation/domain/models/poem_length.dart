/// Model representing a poem length option
class PoemLength {
  final String id;
  final String name;
  final String description;
  final int minLines;
  final int maxLines;
  final bool isPremium;

  const PoemLength({
    required this.id,
    required this.name,
    required this.description,
    required this.minLines,
    required this.maxLines,
    this.isPremium = false,
  });

  /// Factory constructor to create a PoemLength from JSON
  factory PoemLength.fromJson(Map<String, dynamic> json) {
    return PoemLength(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      minLines: json['min_lines'] as int,
      maxLines: json['max_lines'] as int,
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }

  /// Convert PoemLength to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'min_lines': minLines,
      'max_lines': maxLines,
      'is_premium': isPremium,
    };
  }
}

/// Predefined poem lengths
class PoemLengths {
  static const PoemLength short = PoemLength(
    id: 'short',
    name: 'Short',
    description: '4-6 lines, perfect for quick impressions',
    minLines: 4,
    maxLines: 6,
    isPremium: false,
  );

  static const PoemLength medium = PoemLength(
    id: 'medium',
    name: 'Medium',
    description: '8-12 lines, balanced expression',
    minLines: 8,
    maxLines: 12,
    isPremium: false,
  );

  static const PoemLength long = PoemLength(
    id: 'long',
    name: 'Long',
    description: '16+ lines, for deep expressions and narratives',
    minLines: 16,
    maxLines: 24,
    isPremium: true,
  );

  /// Get all available poem lengths
  static List<PoemLength> getAll() {
    return [
      short,
      medium,
      long,
    ];
  }

  /// Get free poem lengths only
  static List<PoemLength> getFree() {
    return getAll().where((length) => !length.isPremium).toList();
  }

  /// Get premium poem lengths only
  static List<PoemLength> getPremium() {
    return getAll().where((length) => length.isPremium).toList();
  }

  /// Get a poem length by ID
  static PoemLength? getById(String id) {
    try {
      return getAll().firstWhere((length) => length.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get default poem length
  static PoemLength getDefault() {
    return medium;
  }
}
