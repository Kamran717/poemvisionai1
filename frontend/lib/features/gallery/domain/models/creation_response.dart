import 'package:frontend/features/gallery/domain/models/creation.dart';

/// Response model for paginated creations
class CreationResponse {
  /// List of creations
  final List<Creation> creations;
  
  /// Total number of creations
  final int total;
  
  /// Current page number
  final int page;
  
  /// Items per page
  final int limit;
  
  /// Whether there is a next page
  final bool hasNextPage;
  
  /// Whether there is a previous page
  final bool hasPreviousPage;
  
  /// Constructor
  const CreationResponse({
    required this.creations,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
  
  /// Create from JSON
  factory CreationResponse.fromJson(Map<String, dynamic> json) {
    final creationsJson = json['creations'] as List<dynamic>;
    final creations = creationsJson
        .map((e) => Creation.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return CreationResponse(
      creations: creations,
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      hasNextPage: json['has_next_page'] as bool,
      hasPreviousPage: json['has_previous_page'] as bool,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'creations': creations.map((e) => e.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'has_next_page': hasNextPage,
      'has_previous_page': hasPreviousPage,
    };
  }
}
