/// Model representing the result of image analysis
class AnalysisResult {
  final String id;
  final String imageUrl;
  final List<String> detectedElements;
  final List<String> suggestedThemes;
  final Map<String, double> emotionScores;
  final DateTime createdAt;
  final String? userNotes;

  const AnalysisResult({
    required this.id,
    required this.imageUrl,
    required this.detectedElements,
    required this.suggestedThemes,
    required this.emotionScores,
    required this.createdAt,
    this.userNotes,
  });

  /// Factory constructor to create an AnalysisResult from JSON
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      detectedElements: (json['detected_elements'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      suggestedThemes: (json['suggested_themes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      emotionScores: Map<String, double>.from(json['emotion_scores'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      userNotes: json['user_notes'] as String?,
    );
  }

  /// Convert AnalysisResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'detected_elements': detectedElements,
      'suggested_themes': suggestedThemes,
      'emotion_scores': emotionScores,
      'created_at': createdAt.toIso8601String(),
      'user_notes': userNotes,
    };
  }

  /// Get the dominant emotion from the emotion scores
  String getDominantEmotion() {
    if (emotionScores.isEmpty) {
      return 'neutral';
    }
    
    final sortedEmotions = emotionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEmotions.first.key;
  }

  /// Get a copy of this AnalysisResult with updated fields
  AnalysisResult copyWith({
    String? id,
    String? imageUrl,
    List<String>? detectedElements,
    List<String>? suggestedThemes,
    Map<String, double>? emotionScores,
    DateTime? createdAt,
    String? userNotes,
  }) {
    return AnalysisResult(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      detectedElements: detectedElements ?? this.detectedElements,
      suggestedThemes: suggestedThemes ?? this.suggestedThemes,
      emotionScores: emotionScores ?? this.emotionScores,
      createdAt: createdAt ?? this.createdAt,
      userNotes: userNotes ?? this.userNotes,
    );
  }

  /// Add a user note to this analysis
  AnalysisResult addNote(String note) {
    return copyWith(userNotes: note);
  }
}
