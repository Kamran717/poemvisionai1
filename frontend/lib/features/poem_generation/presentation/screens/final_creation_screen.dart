import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/presentation/common/app_header.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/services/service_locator.dart';

class FinalCreationScreen extends StatefulWidget {
  final String analysisId;
  
  const FinalCreationScreen({
    super.key,
    required this.analysisId,
  });

  @override
  State<FinalCreationScreen> createState() => _FinalCreationScreenState();
}

class _FinalCreationScreenState extends State<FinalCreationScreen> {
  final ApiClient _apiClient = serviceLocator.get<ApiClient>();
  
  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;
  String? _finalImageUrl;
  String? _shareCode;
  
  // Available frames
  final List<Map<String, dynamic>> _frames = [
    {'id': 'classic', 'name': 'Classic', 'isPremium': false},
    {'id': 'minimalist', 'name': 'Minimalist', 'isPremium': false},
    {'id': 'elegant', 'name': 'Elegant', 'isPremium': false},
    {'id': 'vintage', 'name': 'Vintage', 'isPremium': true},
    {'id': 'ornate', 'name': 'Ornate', 'isPremium': true},
    {'id': 'futuristic', 'name': 'Futuristic', 'isPremium': true},
  ];
  
  // Selected frame
  String _selectedFrame = 'classic';
  
  // Current poem text
  String _poemText = '';
  
  @override
  void initState() {
    super.initState();
    _loadPoemData();
  }
  
  Future<void> _loadPoemData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      AppLogger.d('Loading poem data for ID: ${widget.analysisId}');
      
      // TODO: Implement actual API call
      // This is a placeholder until we implement the actual API call
      // In a real implementation, we would fetch the poem data from the server
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock poem data
      const mockPoem = '''
In golden light the mountains stand,
Reflected in the lake so grand.
The sunset paints the sky with fire,
As nature's beauty we admire.

Tranquility in evening's grace,
A peaceful, serene, sacred place.
The trees in silhouette so still,
This moment time cannot distill.
''';
      
      setState(() {
        _isLoading = false;
        _poemText = mockPoem;
      });
    } catch (e) {
      AppLogger.e('Error loading poem data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load poem data. Please try again.';
      });
    }
  }
  
  Future<void> _createFinalImage() async {
    try {
      setState(() {
        _isCreating = true;
        _errorMessage = null;
      });
      
      AppLogger.d('Creating final image for analysis ID: ${widget.analysisId}');
      AppLogger.d('Selected frame: $_selectedFrame');
      
      // TODO: Implement actual API call
      // This is a placeholder until we implement the actual API call
      // In a real implementation, we would call:
      // final response = await _apiClient.createFinalImage(
      //   analysisId: widget.analysisId,
      //   frameStyle: _selectedFrame,
      // );
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock response data
      setState(() {
        _isCreating = false;
        _finalImageUrl = 'https://example.com/mock-final-image.jpg';
        _shareCode = 'MOCK123';
      });
    } catch (e) {
      AppLogger.e('Error creating final image: $e');
      setState(() {
        _isCreating = false;
        _errorMessage = 'Failed to create final image. Please try again.';
      });
    }
  }
  
  void _shareCreation() {
    AppLogger.d('Sharing creation with code: $_shareCode');
    
    // TODO: Implement sharing functionality
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _downloadCreation() {
    AppLogger.d('Downloading creation');
    
    // TODO: Implement download functionality
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _navigateToHome() {
    AppLogger.d('Navigating to home');
    context.go(RoutePaths.home);
  }
  
  void _navigateToGallery() {
    AppLogger.d('Navigating to gallery');
    context.go(RoutePaths.gallery);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalize Creation'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Finalize Your Creation',
            subtitle: 'Choose a frame style for your poem and image',
          ),
          
          const SizedBox(height: 24),
          
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Final image preview or frame selection
          _finalImageUrl != null
              ? _buildFinalImagePreview()
              : _buildFrameSelection(),
          
          const SizedBox(height: 24),
          
          // Actions
          _finalImageUrl != null
              ? _buildFinalImageActions()
              : _buildCreateFinalImageButton(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildFrameSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poem preview
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Poem',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _poemText,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Frame selection
        const Text(
          'Choose a Frame Style',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _frames.map((frame) {
            final isSelected = _selectedFrame == frame['id'];
            final isPremium = frame['isPremium'] as bool;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFrame = frame['id'] as String;
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.photo_frame,
                            size: 48,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[400],
                          ),
                        ),
                        if (isPremium)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    frame['name'] as String,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCreateFinalImageButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createFinalImage,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: _isCreating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Creating Final Image...'),
                ],
              )
            : const Text('Create Final Image'),
      ),
    );
  }
  
  Widget _buildFinalImagePreview() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.image,
                size: 64,
                color: Colors.grey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Poem is Ready!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share Code: $_shareCode',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinalImageActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                onPressed: _shareCreation,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                onPressed: _downloadCreation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Home'),
                onPressed: _navigateToHome,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                onPressed: _navigateToGallery,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
