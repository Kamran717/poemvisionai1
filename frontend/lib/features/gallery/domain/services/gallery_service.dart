import 'package:frontend/features/gallery/domain/models/creation.dart';
import 'package:frontend/features/gallery/domain/models/creation_response.dart';

/// Gallery service
abstract class GalleryService {
  /// Get all creations
  Future<CreationResponse> getCreations({
    int page = 1,
    int limit = 10,
    String sortBy = 'created_at',
    bool sortDescending = true,
    bool favoritesOnly = false,
    String? search,
  });
  
  /// Get user creations
  Future<List<Creation>> getUserCreations();
  
  /// Get creation by ID
  Future<Creation> getCreationById(String id);
  
  /// Get shared creation by ID
  Future<Creation> getSharedCreationById(String id);
  
  /// Toggle favorite status
  Future<bool> toggleFavorite(String id);
  
  /// Delete creation
  Future<bool> deleteCreation(String id);
  
  /// Share creation
  Future<String?> shareCreation(String id);
  
  /// Update creation privacy
  Future<bool> updatePrivacy(String id, bool isPublic);
  
  /// Export creation as image
  Future<String?> exportCreationAsImage(String id);
}

/// Implementation of gallery service
class GalleryServiceImpl implements GalleryService {
  @override
  Future<CreationResponse> getCreations({
    int page = 1,
    int limit = 10,
    String sortBy = 'created_at',
    bool sortDescending = true,
    bool favoritesOnly = false,
    String? search,
  }) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
    
    // Generate mock data
    final creations = List.generate(
      limit,
      (index) {
        final globalIndex = (page - 1) * limit + index;
        return Creation(
          id: 'creation_$globalIndex',
          title: 'Sample Creation ${globalIndex + 1}',
          content: 'This is a sample poem content for creation ${globalIndex + 1}',
          poemType: globalIndex % 2 == 0 ? 'sonnet' : 'haiku',
          createdAt: DateTime.now().subtract(Duration(days: globalIndex)),
          imageUrl: 'https://picsum.photos/seed/$globalIndex/300/200',
          frameStyle: globalIndex % 3 == 0 ? 'classic' : (globalIndex % 3 == 1 ? 'elegant' : 'minimalist'),
          isFavorite: favoritesOnly || globalIndex % 4 == 0,
        );
      },
    );
    
    // Mock filtering based on search
    final filteredCreations = search != null && search.isNotEmpty
        ? creations.where((c) => 
            c.title.toLowerCase().contains(search.toLowerCase()) ||
            c.content.toLowerCase().contains(search.toLowerCase())
          ).toList()
        : creations;
    
    // Determine if there's a next page
    final hasNextPage = page < 3; // Mock: only 3 pages total
    
    return CreationResponse(
      creations: filteredCreations,
      total: 25, // Mock total count
      page: page,
      limit: limit,
      hasNextPage: hasNextPage,
      hasPreviousPage: page > 1,
    );
  }
  
  @override
  Future<List<Creation>> getUserCreations() async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
    
    // Return mock data
    return List.generate(
      10,
      (index) => Creation(
        id: 'creation_$index',
        title: 'Sample Creation ${index + 1}',
        content: 'This is a sample poem content for creation ${index + 1}',
        poemType: index % 2 == 0 ? 'sonnet' : 'haiku',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        imageUrl: 'https://picsum.photos/seed/$index/300/200',
        frameStyle: 'classic',
        isFavorite: index % 3 == 0,
      ),
    );
  }
  
  @override
  Future<Creation> getCreationById(String id) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock data
    final index = int.tryParse(id.split('_').last) ?? 0;
    return Creation(
      id: id,
      title: 'Sample Creation ${index + 1}',
      content: 'This is a sample poem content for creation ${index + 1}',
      poemType: index % 2 == 0 ? 'sonnet' : 'haiku',
      createdAt: DateTime.now().subtract(Duration(days: index)),
      imageUrl: 'https://picsum.photos/seed/$index/300/200',
      frameStyle: 'classic',
      shareUrl: index % 2 == 0 ? 'https://poemvision.ai/share/$id' : null,
      isPublic: index % 2 == 0,
      isFavorite: index % 3 == 0,
    );
  }
  
  @override
  Future<Creation> getSharedCreationById(String id) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock data
    final index = int.tryParse(id.split('_').last) ?? 0;
    return Creation(
      id: id,
      title: 'Shared Creation ${index + 1}',
      content: 'This is a shared poem content for creation ${index + 1}',
      poemType: index % 2 == 0 ? 'sonnet' : 'haiku',
      createdAt: DateTime.now().subtract(Duration(days: index)),
      imageUrl: 'https://picsum.photos/seed/$index/300/200',
      frameStyle: 'elegant',
      shareUrl: 'https://poemvision.ai/share/$id',
      isPublic: true,
    );
  }
  
  @override
  Future<bool> toggleFavorite(String id) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
  
  @override
  Future<bool> deleteCreation(String id) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
  
  @override
  Future<String?> shareCreation(String id) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 800));
    return 'https://poemvision.ai/share/$id';
  }
  
  @override
  Future<bool> updatePrivacy(String id, bool isPublic) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
  
  @override
  Future<String?> exportCreationAsImage(String id) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
    
    // Return mock file path
    return '/storage/emulated/0/Download/poem_creation_$id.png';
  }
}
