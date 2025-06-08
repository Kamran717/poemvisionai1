import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/presentation/common/app_header.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/services/service_locator.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ApiClient _apiClient = serviceLocator.get<ApiClient>();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _creations = [];
  
  @override
  void initState() {
    super.initState();
    _loadCreations();
  }
  
  Future<void> _loadCreations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      AppLogger.d('Loading user creations');
      
      // TODO: Implement actual API call
      // This is a placeholder until we implement the actual API call
      // In a real implementation, we would call:
      // final response = await _apiClient.getUserCreations();
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock creations data
      final mockCreations = List.generate(8, (index) => {
        'id': index + 1,
        'shareCode': 'SHARE${index + 1}',
        'poemType': index % 3 == 0 ? 'love' : (index % 3 == 1 ? 'inspirational' : 'haiku'),
        'createdAt': DateTime.now().subtract(Duration(days: index)).toString(),
      });
      
      setState(() {
        _isLoading = false;
        _creations = mockCreations;
      });
    } catch (e) {
      AppLogger.e('Error loading creations: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load gallery. Please try again.';
      });
    }
  }
  
  void _viewCreation(String shareCode) {
    AppLogger.d('Viewing creation with share code: $shareCode');
    context.go(RoutePaths.getSharedCreationPath(shareCode));
  }
  
  void _deleteCreation(int id) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Creation'),
        content: const Text('Are you sure you want to delete this creation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDeleteCreation(id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _confirmDeleteCreation(int id) async {
    try {
      AppLogger.d('Deleting creation with ID: $id');
      
      // TODO: Implement actual API call
      // In a real implementation, we would call:
      // final response = await _apiClient.deleteCreation(id);
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update the local list
      setState(() {
        _creations.removeWhere((creation) => creation['id'] == id);
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Creation deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error deleting creation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete creation. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gallery'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
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
    );
  }
  
  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCreations,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_creations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Your gallery is empty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first poem by uploading an image',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Create New Poem'),
                onPressed: () => context.go(RoutePaths.imageUpload),
              ),
            ],
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Your Creations',
            subtitle: 'All your poems in one place',
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _creations.length,
              itemBuilder: (context, index) {
                final creation = _creations[index];
                return _buildCreationCard(creation);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCreationCard(Map<String, dynamic> creation) {
    final id = creation['id'] as int;
    final shareCode = creation['shareCode'] as String;
    final poemType = creation['poemType'] as String;
    final createdAt = DateTime.parse(creation['createdAt'] as String);
    
    // Format the date
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    final formattedDate = '$day/$month/$year';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: InkWell(
              onTap: () => _viewCreation(shareCode),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
          ),
          
          // Info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poemType.capitalize(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, size: 18),
                      onPressed: () => _viewCreation(shareCode),
                      tooltip: 'Share',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _deleteCreation(id),
                      tooltip: 'Delete',
                      color: Colors.red[300],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
