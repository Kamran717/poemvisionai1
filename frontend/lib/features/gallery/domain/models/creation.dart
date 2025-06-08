import 'package:equatable/equatable.dart';
import 'package:frontend/features/poem_generation/domain/models/poem.dart';

/// Creation model representing a saved poem
class Creation extends Equatable {
  /// Unique identifier
  final String id;
  
  /// Title of the creation
  final String title;
  
  /// Content (poem text)
  final String content;
  
  /// Type of poem
  final String poemType;
  
  /// Creation date
  final DateTime createdAt;
  
  /// Image URL
  final String imageUrl;
  
  /// Frame style
  final String frameStyle;
  
  /// Share URL
  final String? shareUrl;
  
  /// Whether the creation is public
  final bool isPublic;
  
  /// Whether the creation is favorited
  final bool isFavorite;
  
  /// Constructor
  const Creation({
    required this.id,
    required this.title,
    required this.content,
    required this.poemType,
    required this.createdAt,
    required this.imageUrl,
    required this.frameStyle,
    this.shareUrl,
    this.isPublic = false,
    this.isFavorite = false,
  });
  
  /// Get the poem associated with this creation
  Poem get poem => Poem(
    id: id,
    title: title,
    content: content,
    poemType: poemType,
    mood: 'Generated',
    generatedAt: createdAt,
  );
  
  /// Get the frame type for this creation
  String get frameType => frameStyle;
  
  @override
  List<Object?> get props => [
    id,
    title,
    content,
    poemType,
    createdAt,
    imageUrl,
    frameStyle,
    shareUrl,
    isPublic,
    isFavorite,
  ];
  
  /// Create a copy with modified properties
  Creation copyWith({
    String? id,
    String? title,
    String? content,
    String? poemType,
    DateTime? createdAt,
    String? imageUrl,
    String? frameStyle,
    String? shareUrl,
    bool? isPublic,
    bool? isFavorite,
  }) {
    return Creation(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      poemType: poemType ?? this.poemType,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      frameStyle: frameStyle ?? this.frameStyle,
      shareUrl: shareUrl ?? this.shareUrl,
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
  
  /// Create from JSON
  factory Creation.fromJson(Map<String, dynamic> json) {
    return Creation(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      poemType: json['poem_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      imageUrl: json['image_url'] as String,
      frameStyle: json['frame_style'] as String,
      shareUrl: json['share_url'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'poem_type': poemType,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
      'frame_style': frameStyle,
      'share_url': shareUrl,
      'is_public': isPublic,
      'is_favorite': isFavorite,
    };
  }
}
