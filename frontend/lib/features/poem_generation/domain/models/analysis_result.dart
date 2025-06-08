import 'package:equatable/equatable.dart';

/// Image analysis result model
class AnalysisResult extends Equatable {
  /// Unique identifier
  final String id;
  
  /// Image ID
  final String imageId;
  
  /// Analysis date
  final DateTime analyzedAt;
  
  /// Content description
  final String contentDescription;
  
  /// Detected subjects
  final List<String> detectedSubjects;
  
  /// Dominant colors
  final List<String> dominantColors;
  
  /// Mood analysis
  final String dominantMood;
  
  /// Scene analysis
  final String sceneType;
  
  /// Constructor
  const AnalysisResult({
    required this.id,
    required this.imageId,
    required this.analyzedAt,
    required this.contentDescription,
    required this.detectedSubjects,
    required this.dominantColors,
    required this.dominantMood,
    required this.sceneType,
  });
  
  @override
  List<Object?> get props => [
    id,
    imageId,
    analyzedAt,
    contentDescription,
    detectedSubjects,
    dominantColors,
    dominantMood,
    sceneType,
  ];
  
  /// Create a copy with modified properties
  AnalysisResult copyWith({
    String? id,
    String? imageId,
    DateTime? analyzedAt,
    String? contentDescription,
    List<String>? detectedSubjects,
    List<String>? dominantColors,
    String? dominantMood,
    String? sceneType,
  }) {
    return AnalysisResult(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      contentDescription: contentDescription ?? this.contentDescription,
      detectedSubjects: detectedSubjects ?? this.detectedSubjects,
      dominantColors: dominantColors ?? this.dominantColors,
      dominantMood: dominantMood ?? this.dominantMood,
      sceneType: sceneType ?? this.sceneType,
    );
  }
  
  /// Create from JSON
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] as String,
      imageId: json['image_id'] as String,
      analyzedAt: DateTime.parse(json['analyzed_at'] as String),
      contentDescription: json['content_description'] as String,
      detectedSubjects: List<String>.from(json['detected_subjects'] as List),
      dominantColors: List<String>.from(json['dominant_colors'] as List),
      dominantMood: json['dominant_mood'] as String,
      sceneType: json['scene_type'] as String,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_id': imageId,
      'analyzed_at': analyzedAt.toIso8601String(),
      'content_description': contentDescription,
      'detected_subjects': detectedSubjects,
      'dominant_colors': dominantColors,
      'dominant_mood': dominantMood,
      'scene_type': sceneType,
    };
  }
}
