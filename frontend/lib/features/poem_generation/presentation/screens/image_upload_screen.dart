import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';

/// Screen to upload images for poem generation
class ImageUploadScreen extends StatefulWidget {
  /// Constructor
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload an Image',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Select or take a photo to create a personalized poem',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textLightColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            
            // Upload area
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Drag and drop an image here',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'or',
                      style: TextStyle(
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Upload buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            
            // Loading indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Uploading image...'),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Create index
        onTap: (index) {
          if (index != 1) {
            switch (index) {
              case 0:
                context.go(RoutePaths.home);
                break;
              case 2:
                context.go(RoutePaths.gallery);
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
  
  void _pickImage() {
    // This would normally use image_picker package
    _mockImageUpload();
  }
  
  void _takePhoto() {
    // This would normally use image_picker package
    _mockImageUpload();
  }
  
  void _mockImageUpload() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate upload delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to customization with mock IDs
        context.go(
          '${RoutePaths.poemCustomization}?image_id=mock123&analysis_id=mock456'
        );
      }
    });
  }
}
