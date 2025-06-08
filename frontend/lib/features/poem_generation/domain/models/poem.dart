import 'package:equatable/equatable.dart';

/// Poem model
class Poem extends Equatable {
  /// Unique identifier
  final String id;
  
  /// Poem title
  final String title;
  
  /// Poem content
  final String content;
  
  /// Type of poem (sonnet, haiku, etc.)
  final String poemType;
  
  /// Mood of the poem
  final String mood;
  
  /// Generation date
  final DateTime generatedAt;
  
  /// Custom prompt used (if any)
  final String? customPrompt;
  
  /// Custom theme (if any)
  final String? theme;
  
  /// Constructor
  const Poem({
    required this.id,
    required this.title,
    required this.content,
    required this.poemType,
    required this.mood,
    required this.generatedAt,
    this.customPrompt,
    this.theme,
  });
  
  @override
  List<Object?> get props => [
    id,
    title,
    content,
    poemType,
    mood,
    generatedAt,
    customPrompt,
    theme,
  ];
  
  /// Create a copy with modified properties
  Poem copyWith({
    String? id,
    String? title,
    String? content,
    String? poemType,
    String? mood,
    DateTime? generatedAt,
    String? customPrompt,
    String? theme,
  }) {
    return Poem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      poemType: poemType ?? this.poemType,
      mood: mood ?? this.mood,
      generatedAt: generatedAt ?? this.generatedAt,
      customPrompt: customPrompt ?? this.customPrompt,
      theme: theme ?? this.theme,
    );
  }
  
  /// Create from JSON
  factory Poem.fromJson(Map<String, dynamic> json) {
    return Poem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      poemType: json['poem_type'] as String,
      mood: json['mood'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      customPrompt: json['custom_prompt'] as String?,
      theme: json['theme'] as String?,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'poem_type': poemType,
      'mood': mood,
      'generated_at': generatedAt.toIso8601String(),
      'custom_prompt': customPrompt,
      'theme': theme,
    };
  }
}
