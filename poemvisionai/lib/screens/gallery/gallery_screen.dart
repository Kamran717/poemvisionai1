import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/creation.dart';
import '../../services/creation_service.dart';
import '../../services/auth_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  CreationService? _creationService;
  bool _isLoading = true;
  List<Creation> _creations = [];
  String? _errorMessage;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    
    if (token != null) {
      setState(() {
        _isAuthenticated = true;
        _creationService = CreationService(token: token);
      });
      _loadCreations();
    } else {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
        _errorMessage = 'Please log in to view your gallery';
      });
    }
  }

  Future<void> _loadCreations() async {
    if (_creationService == null) {
      setState(() {
        _errorMessage = 'Please log in to view your gallery';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final creations = await _creationService!.getUserCreations();
      
      setState(() {
        _creations = creations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load creations: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);

    return Scaffold(
      backgroundColor: primaryBlack,
      appBar: AppBar(
        title: const Text('My Gallery'),
        backgroundColor: primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: yellow))
          : _errorMessage != null
              ? _buildErrorView()
              : _creations.isEmpty
                  ? _buildEmptyView()
                  : _buildGalleryGrid(),
    );
  }

  Widget _buildErrorView() {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    // If not authenticated, show login button instead of "Try Again"
    if (!_isAuthenticated) {
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: sageGreen.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please log in to view your gallery',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your gallery contains all the beautiful poems you\'ve created',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: sageGreen.withOpacity(0.8)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.goNamed('login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Log In'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: blueGray,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // For other errors, show the regular error view
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCreations,
            style: ElevatedButton.styleFrom(
              backgroundColor: blueGray,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_album,
            size: 80,
            color: sageGreen.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your gallery is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first poem to see it here',
            style: TextStyle(
              color: sageGreen.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.goNamed('create'),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Create a Poem'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              backgroundColor: blueGray,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    const Color yellow = Color(0xFFEDD050);
    
    return RefreshIndicator(
      onRefresh: _loadCreations,
      color: yellow,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _creations.length,
        itemBuilder: (context, index) {
          final creation = _creations[index];
          return _buildCreationCard(creation);
        },
      ),
    );
  }

  Widget _buildCreationCard(Creation creation) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to creation detail view
          // This will be implemented when we connect this to the router
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display actual image or final image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                ),
                child: _buildImageWidget(creation),
              ),
            ),
            
            // Poem info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creation.poemType ?? 'Poem',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (creation.poemText != null) ...[
                    Text(
                      creation.poemText!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatDate(creation.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (creation.viewCount > 0) ...[
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${creation.viewCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(Creation creation) {
    try {
      // Try to use final image first, then original image
      String? imageData = creation.finalImageData ?? creation.imageData;
      
      if (imageData != null && imageData.isNotEmpty) {
        // Remove data URL prefix if present
        if (imageData.startsWith('data:')) {
          imageData = imageData.split(',').last;
        }
        
        final bytes = base64Decode(imageData);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } else {
        return _buildPlaceholderImage();
      }
    } catch (e) {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              'Image',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
