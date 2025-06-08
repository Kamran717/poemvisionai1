import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/gallery/domain/models/creation.dart';

/// Paginated creations response
class PaginatedCreationsResponse {
  /// List of creations
  final List<Creation> creations;
  
  /// Total number of creations
  final int total;
  
  /// Current page
  final int currentPage;
  
  /// Total pages
  final int totalPages;
  
  /// Whether there is a next page
  final bool hasNextPage;
  
  /// Constructor
  const PaginatedCreationsResponse({
    required this.creations,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
  });
}

/// Gallery service
class GalleryService {
  /// API client
  final ApiClient _apiClient;
  
  /// Constructor
  GalleryService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  
  /// Get creations
  Future<PaginatedCreationsResponse> getCreations({
    int page = 1,
    int limit = 10,
    String sortBy = 'created_at',
    bool sortDescending = true,
    bool favoritesOnly = false,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_desc': sortDescending,
      };
      
      if (favoritesOnly) {
        queryParams['favorites_only'] = true;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final response = await _apiClient.get('/creations', queryParameters: queryParams);
      
      final List<dynamic> creationsJson = response['creations'] as List<dynamic>;
      final List<Creation> creations = creationsJson
          .map((json) => Creation.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return PaginatedCreationsResponse(
        creations: creations,
        total: response['total'] as int,
        currentPage: response['current_page'] as int,
        totalPages: response['total_pages'] as int,
        hasNextPage: response['has_next_page'] as bool,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Toggle favorite status
  Future<void> toggleFavorite(String creationId) async {
    try {
      await _apiClient.post('/creations/$creationId/toggle-favorite');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Delete creation
  Future<bool> deleteCreation(String creationId) async {
    try {
      await _apiClient.delete('/creations/$creationId');
      return true;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Share creation
  Future<String> shareCreation(String creationId) async {
    try {
      final response = await _apiClient.post('/creations/$creationId/share');
      return response['share_url'] as String;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Export creation as image
  Future<String> exportCreationAsImage(String creationId) async {
    try {
      final response = await _apiClient.post('/creations/$creationId/export');
      return response['image_url'] as String;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get creation by ID
  Future<Creation> getCreationById(String creationId) async {
    try {
      final response = await _apiClient.get('/creations/$creationId');
      return Creation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get shared creation
  Future<Creation> getSharedCreation(String shareId) async {
    try {
      final response = await _apiClient.get('/creations/shared/$shareId');
      return Creation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
