import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/presentation/common/app_header.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/services/service_locator.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final ApiClient _apiClient = serviceLocator.get<ApiClient>();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
        });
        
        AppLogger.d('Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      AppLogger.e('Error picking image: $e');
      setState(() {
        _errorMessage = 'Failed to pick image. Please try again.';
      });
    }
  }
  
  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image first.';
      });
      return;
    }
    
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });
      
      AppLogger.d('Uploading image: ${_selectedImage!.path}');
      
      // TODO: Implement actual API call
      // This is a placeholder until we implement the actual API call
      // In a real implementation, we would call:
      // final response = await _apiClient.analyzeImage(_selectedImage!);
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate a successful analysis with a mock analysis ID
      const String mockAnalysisId = 'mock123';
      
      // Navigate to poem customization screen with the analysis ID
      if (mounted) {
        context.go(RoutePaths.getPoemCustomizationPath(mockAnalysisId));
      }
      
    } catch (e) {
      AppLogger.e('Error uploading image: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed to upload image. Please try again.';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Poem'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(
                title: 'Upload an Image',
                subtitle: 'Choose an image to transform into a beautiful poem',
              ),
              
              const SizedBox(height: 24),
              
              // Image preview or placeholder
              _buildImagePreview(),
              
              const SizedBox(height: 24),
              
              // Image selection options
              _buildImageSelectionOptions(),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
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
              ],
              
              const SizedBox(height: 24),
              
              // Upload button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading || _selectedImage == null ? null : _uploadImage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isUploading
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
                            Text('Analyzing Image...'),
                          ],
                        )
                      : const Text('Transform into Poem'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tips section
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tips for Better Results',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem('Choose clear, high-quality images'),
                      _buildTipItem('Images with strong subjects work best'),
                      _buildTipItem('Landscapes, people, and objects create the most interesting poems'),
                      _buildTipItem('Make sure your image is under 5MB in size'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
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
  
  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: () => _showImageSourceOptions(),
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to select an image',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildImageSelectionOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildOptionButton(
          icon: Icons.photo_library,
          label: 'Gallery',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
        const SizedBox(width: 24),
        _buildOptionButton(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: () => _pickImage(ImageSource.camera),
        ),
      ],
    );
  }
  
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
