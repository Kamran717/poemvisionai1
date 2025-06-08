import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/features/gallery/domain/models/creation.dart';
import 'package:frontend/features/gallery/presentation/providers/gallery_provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _searchController = TextEditingController();
  
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  
  @override
  void initState() {
    super.initState();
    _loadCreations();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // When scrolled to 80% of the list, load more items
      final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
      if (!galleryProvider.isLoadingMore && galleryProvider.hasMorePages) {
        galleryProvider.loadMoreCreations();
      }
    }
  }
  
  Future<void> _loadCreations() async {
    try {
      final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
      await galleryProvider.loadCreations(refresh: true);
    } catch (e) {
      AppLogger.e('Error loading creations', e);
    }
  }
  
  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }
  
  void _showFilterBottomSheet() {
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Favorites filter
                  SwitchListTile(
                    title: const Text('Show favorites only'),
                    value: galleryProvider.showFavoritesOnly,
                    onChanged: (value) {
                      setSheetState(() {
                        galleryProvider.setFavoritesFilter(value);
                      });
                    },
                  ),
                  
                  const Divider(),
                  
                  // Sort options
                  const Text(
                    'Sort by',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  RadioListTile<String>(
                    title: const Text('Date created'),
                    value: 'created_at',
                    groupValue: galleryProvider.sortBy,
                    onChanged: (value) {
                      setSheetState(() {
                        galleryProvider.setSortOptions(
                          value!,
                          galleryProvider.sortDescending,
                        );
                      });
                    },
                  ),
                  
                  RadioListTile<String>(
                    title: const Text('Title'),
                    value: 'title',
                    groupValue: galleryProvider.sortBy,
                    onChanged: (value) {
                      setSheetState(() {
                        galleryProvider.setSortOptions(
                          value!,
                          galleryProvider.sortDescending,
                        );
                      });
                    },
                  ),
                  
                  // Sort direction
                  SwitchListTile(
                    title: const Text('Descending order'),
                    value: galleryProvider.sortDescending,
                    onChanged: (value) {
                      setSheetState(() {
                        galleryProvider.setSortOptions(
                          galleryProvider.sortBy,
                          value,
                        );
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Future<void> _showDeleteConfirmation(Creation creation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Creation'),
        content: Text('Are you sure you want to delete "${creation.poem.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
      final success = await galleryProvider.deleteCreation(creation.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Creation deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  Future<void> _shareCreation(Creation creation) async {
    try {
      final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
      final shareUrl = await galleryProvider.shareCreation(creation.id);
      
      if (shareUrl != null && mounted) {
        // Show sharing options
        // In a real app, we'd use the share_plus package to share the URL
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Creation shared: $shareUrl'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Copy to clipboard
              },
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error sharing creation', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share creation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _exportCreation(Creation creation) async {
    try {
      final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
      final imageUrl = await galleryProvider.exportCreationAsImage(creation.id);
      
      if (imageUrl != null && mounted) {
        // Show export success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Creation exported as image'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error exporting creation', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export creation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _viewCreation(Creation creation) {
    // In a real app, we'd navigate to a detail view
    // For now, just show a modal with the poem
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      creation.poem.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    creation.poem.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      creation.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: creation.isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
                      galleryProvider.toggleFavorite(creation.id);
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to edit screen
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      Navigator.pop(context);
                      _shareCreation(creation);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      Navigator.pop(context);
                      _exportCreation(creation);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(creation);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Creations'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Toggle view button
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List view' : 'Grid view',
            onPressed: _toggleView,
          ),
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search creations',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
                    galleryProvider.clearSearch();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
                  galleryProvider.searchCreations(value);
                }
              },
            ),
          ),
          
          // Creation list/grid
          Expanded(
            child: Consumer<GalleryProvider>(
              builder: (context, galleryProvider, child) {
                if (galleryProvider.isLoading && galleryProvider.filteredCreations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (galleryProvider.filteredCreations.isEmpty) {
                  return _buildEmptyState(galleryProvider);
                }
                
                return _isGridView
                    ? _buildGridView(galleryProvider)
                    : _buildListView(galleryProvider);
              },
            ),
          ),
          
          // Loading more indicator
          Consumer<GalleryProvider>(
            builder: (context, galleryProvider, child) {
              if (galleryProvider.isLoadingMore) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // Gallery index
        onTap: (index) {
          if (index != 2) {
            switch (index) {
              case 0:
                context.go(RoutePaths.home);
                break;
              case 1:
                context.go(RoutePaths.imageUpload);
                break;
              case 3:
                context.go(RoutePaths.profile);
                break;
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(RoutePaths.imageUpload),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState(GalleryProvider galleryProvider) {
    String message = 'No creations found';
    
    if (galleryProvider.showFavoritesOnly) {
      message = 'No favorite creations found';
    } else if (galleryProvider.searchQuery != null) {
      message = 'No creations matching "${galleryProvider.searchQuery}"';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new poem to get started',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(RoutePaths.imageUpload),
            icon: const Icon(Icons.add),
            label: const Text('Create New Poem'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGridView(GalleryProvider galleryProvider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: galleryProvider.filteredCreations.length,
      itemBuilder: (context, index) {
        final creation = galleryProvider.filteredCreations[index];
        return _buildGridItem(creation);
      },
    );
  }
  
  Widget _buildListView(GalleryProvider galleryProvider) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: galleryProvider.filteredCreations.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final creation = galleryProvider.filteredCreations[index];
        return _buildListItem(creation);
      },
    );
  }
  
  Widget _buildGridItem(Creation creation) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return GestureDetector(
      onTap: () => _viewCreation(creation),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage('assets/frames/${creation.frameType}.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.1),
                BlendMode.darken,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Favorite icon and poem type
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        creation.poem.poemType.capitalize(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
                        galleryProvider.toggleFavorite(creation.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          creation.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: creation.isFavorite ? Colors.red : Colors.grey,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Title and preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creation.poem.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      creation.poem.content,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(creation.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildListItem(Creation creation) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return ListTile(
      onTap: () => _viewCreation(creation),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: AssetImage('assets/frames/${creation.frameType}.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        creation.poem.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            creation.poem.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  creation.poem.poemType.capitalize(),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(creation.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (creation.isFavorite)
            const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 20,
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Navigate to edit screen
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          creation.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: creation.isFavorite ? Colors.red : null,
                        ),
                        title: Text(creation.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                        onTap: () {
                          Navigator.pop(context);
                          final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
                          galleryProvider.toggleFavorite(creation.id);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text('Share'),
                        onTap: () {
                          Navigator.pop(context);
                          _shareCreation(creation);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.download),
                        title: const Text('Export as Image'),
                        onTap: () {
                          Navigator.pop(context);
                          _exportCreation(creation);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(creation);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return split('_').map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }
}
