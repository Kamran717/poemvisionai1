import 'package:flutter/foundation.dart';
import 'package:frontend/features/gallery/domain/models/creation.dart';
import 'package:frontend/features/gallery/domain/models/creation_response.dart';
import 'package:frontend/features/gallery/domain/services/gallery_service.dart';

/// Gallery provider
class GalleryProvider extends ChangeNotifier {
  /// Gallery service
  final GalleryService _galleryService;
  
  /// List of all creations
  List<Creation> _creations = [];
  
  /// List of filtered creations
  List<Creation> _filteredCreations = [];
  
  /// Sort by field
  String _sortBy = 'created_at';
  
  /// Sort in descending order
  bool _sortDescending = true;
  
  /// Show favorites only
  bool _showFavoritesOnly = false;
  
  /// Search query
  String? _searchQuery;
  
  /// Loading state
  bool _isLoading = false;
  
  /// Loading more state
  bool _isLoadingMore = false;
  
  /// Has more pages
  bool _hasMorePages = true;
  
  /// Current page
  int _currentPage = 1;
  
  /// Error message
  String? _errorMessage;
  
  /// Constructor
  GalleryProvider({
    required GalleryService galleryService,
  }) : _galleryService = galleryService;
  
  /// Get list of all creations
  List<Creation> get creations => _creations;
  
  /// Get list of filtered creations
  List<Creation> get filteredCreations => _filteredCreations;
  
  /// Get sort by field
  String get sortBy => _sortBy;
  
  /// Get sort direction
  bool get sortDescending => _sortDescending;
  
  /// Get show favorites only
  bool get showFavoritesOnly => _showFavoritesOnly;
  
  /// Get search query
  String? get searchQuery => _searchQuery;
  
  /// Get loading state
  bool get isLoading => _isLoading;
  
  /// Get loading more state
  bool get isLoadingMore => _isLoadingMore;
  
  /// Get has more pages
  bool get hasMorePages => _hasMorePages;
  
  /// Get error message
  String? get errorMessage => _errorMessage;
  
  /// Load creations from API
  Future<void> loadCreations({
    bool refresh = false,
  }) async {
    if (refresh) {
      _isLoading = true;
      _currentPage = 1;
      _hasMorePages = true;
      _errorMessage = null;
      notifyListeners();
    }
    
    try {
      final response = await _galleryService.getCreations(
        page: _currentPage,
        limit: 10,
        sortBy: _sortBy,
        sortDescending: _sortDescending,
        favoritesOnly: _showFavoritesOnly,
        search: _searchQuery,
      );
      
      if (refresh) {
        _creations = response.creations;
      } else {
        _creations = [..._creations, ...response.creations];
      }
      
      _hasMorePages = response.hasNextPage;
      _applyFilters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load more creations
  Future<void> loadMoreCreations() async {
    if (!_hasMorePages || _isLoadingMore) return;
    
    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();
    
    try {
      final response = await _galleryService.getCreations(
        page: _currentPage,
        limit: 10,
        sortBy: _sortBy,
        sortDescending: _sortDescending,
        favoritesOnly: _showFavoritesOnly,
        search: _searchQuery,
      );
      
      _creations = [..._creations, ...response.creations];
      _hasMorePages = response.hasNextPage;
      _applyFilters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _currentPage--; // Revert page increment
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  /// Set favorites filter
  void setFavoritesFilter(bool showFavoritesOnly) {
    _showFavoritesOnly = showFavoritesOnly;
    _applyFilters();
    
    // Reload from API if needed
    loadCreations(refresh: true);
  }
  
  /// Set sort options
  void setSortOptions(String sortBy, bool sortDescending) {
    _sortBy = sortBy;
    _sortDescending = sortDescending;
    _applyFilters();
    
    // Reload from API if needed
    loadCreations(refresh: true);
  }
  
  /// Search creations
  void searchCreations(String query) {
    _searchQuery = query.isNotEmpty ? query : null;
    
    // Reload from API
    loadCreations(refresh: true);
  }
  
  /// Clear search
  void clearSearch() {
    if (_searchQuery != null) {
      _searchQuery = null;
      
      // Reload from API
      loadCreations(refresh: true);
    }
  }
  
  /// Apply filters to creations
  void _applyFilters() {
    // Start with all creations
    _filteredCreations = List.from(_creations);
    
    // Apply local filtering if needed
    // Note: API should handle most filtering, but we can do additional filtering here
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      _filteredCreations = _filteredCreations.where((creation) {
        return creation.title.toLowerCase().contains(query) ||
               creation.content.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply local sorting if needed
    // Note: API should handle most sorting, but we can do additional sorting here
    _filteredCreations.sort((a, b) {
      int result;
      
      switch (_sortBy) {
        case 'title':
          result = a.title.compareTo(b.title);
          break;
        case 'created_at':
        default:
          result = a.createdAt.compareTo(b.createdAt);
          break;
      }
      
      return _sortDescending ? -result : result;
    });
    
    notifyListeners();
  }
  
  /// Toggle favorite status for a creation
  Future<void> toggleFavorite(String creationId) async {
    try {
      // Optimistic update
      final index = _creations.indexWhere((c) => c.id == creationId);
      if (index != -1) {
        final creation = _creations[index];
        final updatedCreation = creation.copyWith(
          isFavorite: !creation.isFavorite,
        );
        
        _creations[index] = updatedCreation;
        _applyFilters();
      }
      
      // Call API
      await _galleryService.toggleFavorite(creationId);
    } catch (e) {
      // Revert on error
      final index = _creations.indexWhere((c) => c.id == creationId);
      if (index != -1) {
        final creation = _creations[index];
        final revertedCreation = creation.copyWith(
          isFavorite: !creation.isFavorite,
        );
        
        _creations[index] = revertedCreation;
        _applyFilters();
      }
      
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  /// Delete a creation
  Future<bool> deleteCreation(String creationId) async {
    try {
      // Optimistic update
      final originalCreations = List<Creation>.from(_creations);
      
      _creations.removeWhere((c) => c.id == creationId);
      _applyFilters();
      
      // Call API
      final success = await _galleryService.deleteCreation(creationId);
      
      if (!success) {
        // Revert on error
        _creations = originalCreations;
        _applyFilters();
      }
      
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Share a creation
  Future<String?> shareCreation(String creationId) async {
    try {
      final shareUrl = await _galleryService.shareCreation(creationId);
      return shareUrl;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  /// Export creation as image
  Future<String?> exportCreationAsImage(String creationId) async {
    try {
      final imageUrl = await _galleryService.exportCreationAsImage(creationId);
      return imageUrl;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
