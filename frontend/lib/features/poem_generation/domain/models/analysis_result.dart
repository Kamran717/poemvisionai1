import 'package:equatable/equatable.dart';

/// Represents the result of image analysis from the backend
class AnalysisResult extends Equatable {
  /// ID of the analysis
  final String? id;
  
  /// URL of the analyzed image
  final String? imageUrl;
  
  /// Detected objects in the image
  final List<String> detectedObjects;
  
  /// Detected scenes in the image
  final List<String> detectedScenes;
  
  /// Detected colors in the image
  final List<String> dominantColors;
  
  /// Detected emotions in the image
  final List<String> emotions;
  
  /// Primary theme of the image
  final String primaryTheme;
  
  /// Time period suggested by the image
  final String? timePeriod;
  
  /// Overall mood of the image
  final String mood;
  
  /// Suggested poem themes
  final List<String> suggestedThemes;
  
  /// Suggested poem types that would match the image
  final List<String> suggestedPoemTypes;
  
  /// Raw confidence scores for various elements
  final Map<String, double> confidenceScores;
  
  /// Creation timestamp
  final DateTime? createdAt;
  
  /// User notes
  final String? userNotes;
  
  /// Constructor
  const AnalysisResult({
    this.id,
    this.imageUrl,
    required this.detectedObjects,
    required this.detectedScenes,
    required this.dominantColors,
    required this.emotions,
    required this.primaryTheme,
    this.timePeriod,
    required this.mood,
    required this.suggestedThemes,
    required this.suggestedPoemTypes,
    required this.confidenceScores,
    this.createdAt,
    this.userNotes,
  });
  
  /// Create from JSON
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] as String?,
      imageUrl: json['image_url'] as String?,
      detectedObjects: List<String>.from(json['detected_objects'] ?? []),
      detectedScenes: List<String>.from(json['detected_scenes'] ?? []),
      dominantColors: List<String>.from(json['dominant_colors'] ?? []),
      emotions: List<String>.from(json['emotions'] ?? []),
      primaryTheme: json['primary_theme'] as String? ?? 'Unknown',
      timePeriod: json['time_period'] as String?,
      mood: json['mood'] as String? ?? 'Neutral',
      suggestedThemes: List<String>.from(json['suggested_themes'] ?? []),
      suggestedPoemTypes: List<String>.from(json['suggested_poem_types'] ?? []),
      confidenceScores: Map<String, double>.from(json['confidence_scores'] ?? {}),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      userNotes: json['user_notes'] as String?,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'detected_objects': detectedObjects,
      'detected_scenes': detectedScenes,
      'dominant_colors': dominantColors,
      'emotions': emotions,
      'primary_theme': primaryTheme,
      'time_period': timePeriod,
      'mood': mood,
      'suggested_themes': suggestedThemes,
      'suggested_poem_types': suggestedPoemTypes,
      'confidence_scores': confidenceScores,
      'created_at': createdAt?.toIso8601String(),
      'user_notes': userNotes,
    };
  }
  
  /// Create empty analysis result
  factory AnalysisResult.empty() {
    return AnalysisResult(
      detectedObjects: [],
      detectedScenes: [],
      dominantColors: [],
      emotions: [],
      primaryTheme: 'Unknown',
      mood: 'Neutral',
      suggestedThemes: [],
      suggestedPoemTypes: [],
      confidenceScores: {},
    );
  }
  
  /// Create a copy with some fields changed
  AnalysisResult copyWith({
    String? id,
    String? imageUrl,
    List<String>? detectedObjects,
    List<String>? detectedScenes,
    List<String>? dominantColors,
    List<String>? emotions,
    String? primaryTheme,
    String? timePeriod,
    String? mood,
    List<String>? suggestedThemes,
    List<String>? suggestedPoemTypes,
    Map<String, double>? confidenceScores,
    DateTime? createdAt,
    String? userNotes,
  }) {
    return AnalysisResult(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      detectedObjects: detectedObjects ?? this.detectedObjects,
      detectedScenes: detectedScenes ?? this.detectedScenes,
      dominantColors: dominantColors ?? this.dominantColors,
      emotions: emotions ?? this.emotions,
      primaryTheme: primaryTheme ?? this.primaryTheme,
      timePeriod: timePeriod ?? this.timePeriod,
      mood: mood ?? this.mood,
      suggestedThemes: suggestedThemes ?? this.suggestedThemes,
      suggestedPoemTypes: suggestedPoemTypes ?? this.suggestedPoemTypes,
      confidenceScores: confidenceScores ?? this.confidenceScores,
      createdAt: createdAt ?? this.createdAt,
      userNotes: userNotes ?? this.userNotes,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    imageUrl,
    detectedObjects,
    detectedScenes,
    dominantColors,
    emotions,
    primaryTheme,
    timePeriod,
    mood,
    suggestedThemes,
    suggestedPoemTypes,
    confidenceScores,
    createdAt,
    userNotes,
  ];
}
