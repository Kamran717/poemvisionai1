import 'package:equatable/equatable.dart';

/// Represents a poem
class Poem extends Equatable {
  /// Unique identifier
  final String id;
  
  /// Poem title
  final String title;
  
  /// Poem content
  final String content;
  
  /// Type of poem (e.g., "sonnet", "haiku", etc.)
  final String poemType;
  
  /// Image ID associated with this poem
  final String? imageId;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Last update timestamp
  final DateTime? updatedAt;
  
  /// User who created the poem
  final String? userId;
  
  /// Constructor
  const Poem({
    required this.id,
    required this.title,
    required this.content,
    required this.poemType,
    this.imageId,
    required this.createdAt,
    this.updatedAt,
    this.userId,
  });
  
  /// Create from JSON
  factory Poem.fromJson(Map<String, dynamic> json) {
    return Poem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      poemType: json['poem_type'] as String,
      imageId: json['image_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      userId: json['user_id'] as String?,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'poem_type': poemType,
      'image_id': imageId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_id': userId,
    };
  }
  
  /// Create a copy with some fields changed
  Poem copyWith({
    String? id,
    String? title,
    String? content,
    String? poemType,
    String? imageId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Poem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      poemType: poemType ?? this.poemType,
      imageId: imageId ?? this.imageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
  
  /// Create an empty poem
  factory Poem.empty() {
    return Poem(
      id: '',
      title: '',
      content: '',
      poemType: '',
      createdAt: DateTime.now(),
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    title,
    content,
    poemType,
    imageId,
    createdAt,
    updatedAt,
    userId,
  ];
}
