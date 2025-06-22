import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/creation.dart';
import 'api_service.dart';

class CreationService {
  final ApiService _apiService;
  final ImagePicker _imagePicker = ImagePicker();

  CreationService({ApiService? apiService, String? token}) 
      : _apiService = apiService ?? ApiService(token: token);

  // Request camera permission
  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true; // Web doesn't need explicit permission
    
    try {
      // Check current permission status first
      final currentStatus = await Permission.camera.status;
      if (currentStatus == PermissionStatus.granted) {
        return true;
      }
      
      // Request camera permission
      final status = await Permission.camera.request();
      
      // If permanently denied, guide user to settings
      if (status == PermissionStatus.permanentlyDenied) {
        return await openAppSettings();
      }
      
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  // Request gallery permission with simplified logic
  Future<bool> _requestGalleryPermission() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        // Try multiple permission strategies for different Android versions
        // Prioritize storage permission since it's more reliable across devices
        List<Permission> permissionsToTry = [
          Permission.storage, // More reliable across Android versions
          Permission.photos,  // For Android 13+ (when properly configured)
        ];
        
        for (Permission permission in permissionsToTry) {
          try {
            // Check current status
            final currentStatus = await permission.status;
            
            if (currentStatus == PermissionStatus.granted) {
              return true;
            }
            
            // Request permission
            final status = await permission.request();
            
            if (status == PermissionStatus.granted) {
              return true;
            }
            
            if (status == PermissionStatus.permanentlyDenied) {
              return await openAppSettings();
            }
            
          } catch (e) {
            // Continue to next permission
            continue;
          }
        }
        
        return false;
        
      } else if (Platform.isIOS) {
        // Check current status first
        final currentStatus = await Permission.photos.status;
        
        if (currentStatus == PermissionStatus.granted) {
          return true;
        }
        
        final status = await Permission.photos.request();
        
        if (status == PermissionStatus.permanentlyDenied) {
          return await openAppSettings();
        }
        
        return status == PermissionStatus.granted;
      }
    } catch (e) {
      return false;
    }

    return false;
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      rethrow;
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      // Check if storage permission is granted (most reliable)
      final storageStatus = await Permission.storage.status;
      
      if (storageStatus != PermissionStatus.granted) {
        final hasStoragePermission = await _requestGalleryPermission();
        if (!hasStoragePermission) {
          throw Exception('Gallery permission denied - storage access required');
        }
      }
      
      // Try image picker since storage permission is granted
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Verify file exists and is readable
        final file = File(pickedFile.path);
        final exists = await file.exists();
        if (exists) {
          return file;
        } else {
          throw Exception('Selected image file is not accessible');
        }
      } else {
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Convert an image file to base64
  Future<String> imageFileToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  // Upload an image and analyze it
  Future<Creation> uploadAndAnalyzeImage(File? imageFile, Map<String, dynamic> preferences) async {
    try {
      if (imageFile == null) {
        throw Exception('No image file provided');
      }

      // Validate file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Selected image file does not exist');
      }

      // For web platform, use mock data (image picker may not work the same way)
      if (kIsWeb) {
        // Simulate a delay
        await Future.delayed(const Duration(seconds: 2));
        
        // Mock creation ID between 1-1000
        final mockId = Random().nextInt(1000) + 1;
        
        return Creation(
          id: mockId,
          imageData: 'mock_image_data',
          createdAt: DateTime.now(),
        );
      }
      
      // Convert image to base64 for native platforms
      final base64Image = await imageFileToBase64(imageFile);
      
      // Upload the image for analysis
      final creation = await _apiService.uploadImage(base64Image, preferences);
      
      return creation;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // Generate a poem from an analyzed image
  Future<Creation> generatePoem(Creation uploadedCreation, Map<String, dynamic> poemPreferences) async {
    try {
      // Get the analysisId from the shareCode field where we stored it
      final analysisId = uploadedCreation.shareCode;
      if (analysisId == null) {
        throw Exception('No analysis ID found for this creation');
      }
      
      final creation = await _apiService.generatePoem(analysisId, poemPreferences);
      return creation;
    } catch (e) {
      rethrow;
    }
  }

  // Get all creations for the current user
  Future<List<Creation>> getUserCreations() async {
    try {
      final creations = await _apiService.getUserCreations();
      return creations;
    } catch (e) {
      debugPrint('Error getting user creations: $e');
      rethrow;
    }
  }

  // Get a specific creation by ID
  Future<Creation> getCreationById(int creationId) async {
    try {
      final creation = await _apiService.getCreationById(creationId);
      return creation;
    } catch (e) {
      debugPrint('Error getting creation: $e');
      rethrow;
    }
  }

  // Get a shared creation by share code
  Future<Creation> getSharedCreation(String shareCode) async {
    try {
      final creation = await _apiService.getCreationByShareCode(shareCode);
      return creation;
    } catch (e) {
      debugPrint('Error getting shared creation: $e');
      rethrow;
    }
  }

  // Helper method to convert base64 image to a displayable format
  static Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }
}
