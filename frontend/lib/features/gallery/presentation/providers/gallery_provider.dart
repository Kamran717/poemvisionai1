import 'package:flutter/foundation.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/gallery/domain/models/creation.dart';
import 'package:frontend/features/gallery/domain/services/gallery_service.dart';

/// Provider for gallery functionality
class GalleryProvider extends ChangeNotifier {
  final GalleryService _galleryService;
  
  // Creations
  List<Creation> _creations = [];
  List<Creation> get creations => _creations;
  
  // Filtered creations
  List<Creation> _filteredCreations = [];
  List<Creation> get filteredCreations => _filteredCreations;
  
  // Selected creation
  Creation? _selectedCreation;
  Creation? get selectedCreation => _selectedCreation;
  
  // Filter and sort options
  bool _showFavoritesOnly = false;
  bool get showFavoritesOnly => _showFavoritesOnly;
  
  String _sortBy = 'created_at';
  String get sortBy => _sortBy;
  
  bool _sortDescending = true;
  bool get sortDescending => _sortDescending;
  
  String? _searchQuery;
  String? get searchQuery => _searchQuery;
  
  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Pagination
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMorePages = true;
  bool get hasMorePages => _hasMorePages;
  
  GalleryProvider(this._galleryService);
  
  /// Load user creations
  Future<void> loadCreations({bool refresh = false}) async {
    if (_isLoading) return;
    
    try {
      if (refresh) {
        _setLoading(true);
        _currentPage = 0;
        _hasMorePages = true;
      }
      
      // Get creations
      final creations = await _galleryService.getUserCreations(
        favoritesOnly: _showFavoritesOnly,
        sortBy: _sortBy,
        descending: _sortDescending,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      
      // Update state
      if (refresh || _currentPage == 0) {
        _creations = creations;
      } else {
        _creations.addAll(creations);
      }
      
      // Check if there are more pages
      _hasMorePages = creations.length == _pageSize;
      
      // Increment page number
      _currentPage++;
      
      // Apply filters
      _applyFilters();
      
      _setLoading(false);
    } catch (e) {
      AppLogger.e('Error loading creations', e);
      _setError('Failed to load creations');
    }
  }
  
  /// Load more creations (pagination)
  Future<void> loadMoreCreations() async {
    if (_isLoadingMore || !_hasMorePages) return;
    
    try {
      _isLoadingMore = true;
      notifyListeners();
      
      await loadCreations();
      
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error loading more creations', e);
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  /// Get a specific creation by ID
  Future<Creation?> getCreationById(String creationId) async {
    try {
      _setLoading(true);
      
      // Try to find creation in current list
      final existingCreation = _creations.firstWhere(
        (creation) => creation.id == creationId,
        orElse: () => null as Creation,
      );
      
      if (existingCreation != null) {
        _selectedCreation = existingCreation;
        _setLoading(false);
        return existingCreation;
      }
      
      // If not found, fetch from API
      final creation = await _galleryService.getCreationById(creationId);
      _selectedCreation = creation;
      
      _setLoading(false);
      return creation;
    } catch (e) {
      AppLogger.e('Error getting creation by ID', e);
      _setError('Failed to get creation');
      return null;
    }
  }
  
  /// Set selected creation
  void setSelectedCreation(Creation creation) {
    _selectedCreation = creation;
    notifyListeners();
  }
  
  /// Toggle favorite status of a creation
  Future<bool> toggleFavorite(String creationId) async {
    try {
      // Get the creation
      final creationIndex = _creations.indexWhere((c) => c.id == creationId);
      if (creationIndex == -1) return false;
      
      // Toggle favorite in UI immediately for better UX
      final updatedCreation = _creations[creationIndex].toggleFavorite();
      _creations[creationIndex] = updatedCreation;
      
      // Update selected creation if necessary
      if (_selectedCreation?.id == creationId) {
        _selectedCreation = updatedCreation;
      }
      
      // Apply filters
      _applyFilters();
      
      notifyListeners();
      
      // Call API to update favorite status
      final result = await _galleryService.toggleFavorite(creationId);
      
      // Update with server response
      _creations[creationIndex] = result;
      
      if (_selectedCreation?.id == creationId) {
        _selectedCreation = result;
      }
      
      // Apply filters again with updated data
      _applyFilters();
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.e('Error toggling favorite', e);
      _setError('Failed to update favorite status');
      return false;
    }
  }
  
  /// Delete a creation
  Future<bool> deleteCreation(String creationId) async {
    try {
      final success = await _galleryService.deleteCreation(creationId);
      
      if (success) {
        // Remove from list
        _creations.removeWhere((c) => c.id == creationId);
        
        // Clear selected creation if necessary
        if (_selectedCreation?.id == creationId) {
          _selectedCreation = null;
        }
        
        // Apply filters
        _applyFilters();
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      AppLogger.e('Error deleting creation', e);
      _setError('Failed to delete creation');
      return false;
    }
  }
  
  /// Share a creation
  Future<String?> shareCreation(String creationId) async {
    try {
      final shareUrl = await _galleryService.shareCreation(creationId);
      
      // Update creation with share URL
      final creationIndex = _creations.indexWhere((c) => c.id == creationId);
      if (creationIndex != -1) {
        _creations[creationIndex] = _creations[creationIndex].withShareUrl(shareUrl);
        
        if (_selectedCreation?.id == creationId) {
          _selectedCreation = _creations[creationIndex];
        }
        
        notifyListeners();
      }
      
      return shareUrl;
    } catch (e) {
      AppLogger.e('Error sharing creation', e);
      _setError('Failed to share creation');
      return null;
    }
  }
  
  /// Export creation as image
  Future<String?> exportCreationAsImage(String creationId) async {
    try {
      return await _galleryService.exportCreationAsImage(creationId);
    } catch (e) {
      AppLogger.e('Error exporting creation', e);
      _setError('Failed to export creation');
      return null;
    }
  }
  
  /// Set favorites filter
  void setFavoritesFilter(bool showFavoritesOnly) {
    _showFavoritesOnly = showFavoritesOnly;
    _applyFilters();
    notifyListeners();
  }
  
  /// Set sort options
  void setSortOptions(String sortBy, bool descending) {
    _sortBy = sortBy;
    _sortDescending = descending;
    loadCreations(refresh: true);
  }
  
  /// Search creations
  Future<void> searchCreations(String query) async {
    if (query.isEmpty) {
      _searchQuery = null;
      _applyFilters();
      notifyListeners();
      return;
    }
    
    try {
      _setLoading(true);
      _searchQuery = query;
      
      final results = await _galleryService.searchCreations(query);
      _creations = results;
      _applyFilters();
      
      _setLoading(false);
    } catch (e) {
      AppLogger.e('Error searching creations', e);
      _setError('Failed to search creations');
    }
  }
  
  /// Clear search
  void clearSearch() {
    _searchQuery = null;
    loadCreations(refresh: true);
  }
  
  /// Apply filters to creations
  void _applyFilters() {
    _filteredCreations = List.from(_creations);
    
    // Apply favorites filter
    if (_showFavoritesOnly) {
      _filteredCreations = _filteredCreations.where((c) => c.isFavorite).toList();
    }
    
    // Sort locally if needed
    if (_sortBy == 'title') {
      _filteredCreations.sort((a, b) {
        final result = a.poem.title.compareTo(b.poem.title);
        return _sortDescending ? -result : result;
      });
    } else if (_sortBy == 'created_at' && (_creations.length != _pageSize || _currentPage > 1)) {
      // Only sort by date locally if we have loaded more than one page or have all results
      _filteredCreations.sort((a, b) {
        final result = a.createdAt.compareTo(b.createdAt);
        return _sortDescending ? -result : result;
      });
    }
    
    notifyListeners();
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
}
