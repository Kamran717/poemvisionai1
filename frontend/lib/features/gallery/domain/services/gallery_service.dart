import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/gallery/domain/models/creation.dart';

/// Service for handling gallery operations
class GalleryService {
  final ApiClient _apiClient;

  GalleryService(this._apiClient);

  /// Get all user creations
  Future<List<Creation>> getUserCreations({
    bool favoritesOnly = false,
    String? sortBy,
    bool descending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.d('Getting user creations');
      
      // Build query parameters
      final Map<String, dynamic> queryParams = {};
      
      if (favoritesOnly) {
        queryParams['favorites_only'] = 'true';
      }
      
      if (sortBy != null) {
        queryParams['sort_by'] = sortBy;
        queryParams['descending'] = descending.toString();
      }
      
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      
      if (offset != null) {
        queryParams['offset'] = offset.toString();
      }
      
      final response = await _apiClient.get(
        '/api/creations',
        queryParameters: queryParams,
      );
      
      if (response.isSuccess && response.data != null) {
        final creationsData = response.data! as List<dynamic>;
        return creationsData.map((data) => Creation.fromJson(data)).toList();
      } else {
        throw Exception(response.error?.message ?? 'Failed to get user creations');
      }
    } catch (e) {
      AppLogger.e('Error getting user creations', e);
      
      // During development, return mock data if API call fails
      if (e.toString().contains('Failed to get user creations')) {
        return _getMockCreations();
      }
      
      rethrow;
    }
  }

  /// Get a specific creation by ID
  Future<Creation> getCreationById(String creationId) async {
    try {
      AppLogger.d('Getting creation by ID: $creationId');
      
      final response = await _apiClient.get('/api/creations/$creationId');
      
      if (response.isSuccess && response.data != null) {
        final creationData = response.data!;
        return Creation.fromJson(creationData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to get creation');
      }
    } catch (e) {
      AppLogger.e('Error getting creation by ID', e);
      rethrow;
    }
  }

  /// Save a creation
  Future<Creation> saveCreation(Creation creation) async {
    try {
      AppLogger.d('Saving creation: ${creation.id}');
      
      final response = await _apiClient.put(
        '/api/creations/${creation.id}',
        data: creation.toJson(),
      );
      
      if (response.isSuccess && response.data != null) {
        final updatedCreationData = response.data!;
        return Creation.fromJson(updatedCreationData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to save creation');
      }
    } catch (e) {
      AppLogger.e('Error saving creation', e);
      rethrow;
    }
  }

  /// Delete a creation
  Future<bool> deleteCreation(String creationId) async {
    try {
      AppLogger.d('Deleting creation: $creationId');
      
      final response = await _apiClient.delete('/api/creations/$creationId');
      
      return response.isSuccess;
    } catch (e) {
      AppLogger.e('Error deleting creation', e);
      rethrow;
    }
  }

  /// Toggle favorite status of a creation
  Future<Creation> toggleFavorite(String creationId) async {
    try {
      AppLogger.d('Toggling favorite for creation: $creationId');
      
      final response = await _apiClient.post('/api/creations/$creationId/toggle-favorite');
      
      if (response.isSuccess && response.data != null) {
        final updatedCreationData = response.data!;
        return Creation.fromJson(updatedCreationData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to toggle favorite');
      }
    } catch (e) {
      AppLogger.e('Error toggling favorite', e);
      rethrow;
    }
  }

  /// Share a creation publicly
  Future<String> shareCreation(String creationId) async {
    try {
      AppLogger.d('Sharing creation: $creationId');
      
      final response = await _apiClient.post('/api/creations/$creationId/share');
      
      if (response.isSuccess && response.data != null) {
        final shareData = response.data!;
        return shareData['share_url'] as String;
      } else {
        throw Exception(response.error?.message ?? 'Failed to share creation');
      }
    } catch (e) {
      AppLogger.e('Error sharing creation', e);
      rethrow;
    }
  }

  /// Export creation as image
  Future<String> exportCreationAsImage(String creationId) async {
    try {
      AppLogger.d('Exporting creation as image: $creationId');
      
      final response = await _apiClient.get('/api/creations/$creationId/export-image');
      
      if (response.isSuccess && response.data != null) {
        final exportData = response.data!;
        return exportData['image_url'] as String;
      } else {
        throw Exception(response.error?.message ?? 'Failed to export creation');
      }
    } catch (e) {
      AppLogger.e('Error exporting creation', e);
      rethrow;
    }
  }

  /// Search creations by keyword
  Future<List<Creation>> searchCreations(String query) async {
    try {
      AppLogger.d('Searching creations with query: $query');
      
      final response = await _apiClient.get(
        '/api/creations/search',
        queryParameters: {'q': query},
      );
      
      if (response.isSuccess && response.data != null) {
        final creationsData = response.data! as List<dynamic>;
        return creationsData.map((data) => Creation.fromJson(data)).toList();
      } else {
        throw Exception(response.error?.message ?? 'Failed to search creations');
      }
    } catch (e) {
      AppLogger.e('Error searching creations', e);
      rethrow;
    }
  }

  /// Generate mock creations for development
  List<Creation> _getMockCreations() {
    final now = DateTime.now();
    
    return List.generate(
      10,
      (index) => Creation(
        id: 'creation_${index + 1}',
        poem: Poem(
          id: 'poem_${index + 1}',
          content: _getMockPoemContent(index),
          title: 'Sample Poem ${index + 1}',
          poemType: index % 3 == 0 ? 'haiku' : (index % 3 == 1 ? 'sonnet' : 'free_verse'),
          analysisId: 'analysis_${index + 1}',
          createdAt: now.subtract(Duration(days: index)),
        ),
        frameType: index % 5 == 0 ? 'classic' : (index % 5 == 1 ? 'elegant' : (index % 5 == 2 ? 'minimalist' : (index % 5 == 3 ? 'vintage' : 'ornate'))),
        createdAt: now.subtract(Duration(days: index)),
        isFavorite: index % 3 == 0,
        isPublic: index % 2 == 0,
        viewCount: (index + 1) * 5,
        likeCount: (index + 1) * 2,
      ),
    );
  }

  /// Generate mock poem content for development
  String _getMockPoemContent(int index) {
    final poemTypes = ['haiku', 'sonnet', 'free_verse'];
    final poemType = poemTypes[index % 3];
    
    if (poemType == 'haiku') {
      return 'Morning sunlight gleams\n'
          'Petals dance in gentle breeze\n'
          'Spring awakens life';
    } else if (poemType == 'sonnet') {
      return 'The gentle rain falls soft upon the ground,\n'
          'As nature\'s tears refresh the thirsty earth.\n'
          'The pitter-patter makes a soothing sound,\n'
          'A cleansing ritual, a kind of rebirth.\n\n'
          'Each droplet holds a promise all its own,\n'
          'Of growth and green and life about to start.\n'
          'The seeds below, so patiently they\'ve grown,\n'
          'Now drink the rain with eager, open heart.\n\n'
          'When clouds depart and sun returns once more,\n'
          'The world shines bright, renewed and washed so clean.\n'
          'The rainbow arcs from distant shore to shore,\n'
          'A painted promise of what\'s yet unseen.\n\n'
          'So let the rain fall freely from above,\n'
          'Nature\'s reminder of renewal and love.';
    } else {
      return 'The city wakes\n'
          'Stretching its concrete arms\n'
          'Into the morning light.\n\n'
          'Windows flicker to life,\n'
          'One by one,\n'
          'Like stars in reverse.\n\n'
          'The rhythm begins:\n'
          'Footsteps, car horns, voices\n'
          'The heartbeat of urban life.\n\n'
          'And I watch,\n'
          'A silent observer\n'
          'Of this daily renaissance.';
    }
  }
}
