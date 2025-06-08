import 'package:frontend/features/poem_generation/domain/models/poem.dart';
import 'package:frontend/features/poem_generation/domain/models/analysis_result.dart';

/// Model representing a user's creation (a poem with its associated image analysis)
class Creation {
  final String id;
  final Poem poem;
  final AnalysisResult? analysis;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String frameType;
  final bool isFavorite;
  final bool isPublic;
  final int viewCount;
  final int likeCount;
  final String? shareUrl;
  final Map<String, dynamic>? metadata;

  const Creation({
    required this.id,
    required this.poem,
    this.analysis,
    required this.createdAt,
    this.updatedAt,
    required this.frameType,
    this.isFavorite = false,
    this.isPublic = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.shareUrl,
    this.metadata,
  });

  /// Factory constructor to create a Creation from JSON
  factory Creation.fromJson(Map<String, dynamic> json) {
    return Creation(
      id: json['id'] as String,
      poem: Poem.fromJson(json['poem'] as Map<String, dynamic>),
      analysis: json['analysis'] != null
          ? AnalysisResult.fromJson(json['analysis'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      frameType: json['frame_type'] as String,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isPublic: json['is_public'] as bool? ?? false,
      viewCount: json['view_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      shareUrl: json['share_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert Creation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poem': poem.toJson(),
      'analysis': analysis?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'frame_type': frameType,
      'is_favorite': isFavorite,
      'is_public': isPublic,
      'view_count': viewCount,
      'like_count': likeCount,
      'share_url': shareUrl,
      'metadata': metadata,
    };
  }

  /// Get a copy of this Creation with updated fields
  Creation copyWith({
    String? id,
    Poem? poem,
    AnalysisResult? analysis,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? frameType,
    bool? isFavorite,
    bool? isPublic,
    int? viewCount,
    int? likeCount,
    String? shareUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Creation(
      id: id ?? this.id,
      poem: poem ?? this.poem,
      analysis: analysis ?? this.analysis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      frameType: frameType ?? this.frameType,
      isFavorite: isFavorite ?? this.isFavorite,
      isPublic: isPublic ?? this.isPublic,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      shareUrl: shareUrl ?? this.shareUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Toggle favorite status
  Creation toggleFavorite() {
    return copyWith(
      isFavorite: !isFavorite,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle public status
  Creation togglePublic() {
    return copyWith(
      isPublic: !isPublic,
      updatedAt: DateTime.now(),
    );
  }

  /// Update share URL
  Creation withShareUrl(String url) {
    return copyWith(
      shareUrl: url,
      isPublic: true,
      updatedAt: DateTime.now(),
    );
  }
}
