import 'package:equatable/equatable.dart';
import 'package:frontend/features/poem_generation/domain/models/poem.dart';

/// Represents a complete poem creation with frame
class Creation extends Equatable {
  /// Unique identifier
  final String id;
  
  /// Poem data
  final Poem poem;
  
  /// Type of frame
  final String frameType;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Whether the creation is marked as favorite
  final bool isFavorite;
  
  /// Public share link (if shared)
  final String? shareLink;
  
  /// Number of views (if shared)
  final int views;
  
  /// User notes
  final String? notes;
  
  /// Constructor
  const Creation({
    required this.id,
    required this.poem,
    required this.frameType,
    required this.createdAt,
    this.isFavorite = false,
    this.shareLink,
    this.views = 0,
    this.notes,
  });
  
  /// Create from JSON
  factory Creation.fromJson(Map<String, dynamic> json) {
    return Creation(
      id: json['id'] as String,
      poem: Poem.fromJson(json['poem'] as Map<String, dynamic>),
      frameType: json['frame_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isFavorite: json['is_favorite'] as bool? ?? false,
      shareLink: json['share_link'] as String?,
      views: json['views'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poem': poem.toJson(),
      'frame_type': frameType,
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite,
      'share_link': shareLink,
      'views': views,
      'notes': notes,
    };
  }
  
  /// Create a copy with some fields changed
  Creation copyWith({
    String? id,
    Poem? poem,
    String? frameType,
    DateTime? createdAt,
    bool? isFavorite,
    String? shareLink,
    int? views,
    String? notes,
  }) {
    return Creation(
      id: id ?? this.id,
      poem: poem ?? this.poem,
      frameType: frameType ?? this.frameType,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      shareLink: shareLink ?? this.shareLink,
      views: views ?? this.views,
      notes: notes ?? this.notes,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    poem,
    frameType,
    createdAt,
    isFavorite,
    shareLink,
    views,
    notes,
  ];
}
