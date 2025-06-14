import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/creation.dart';
import 'api_service.dart';

class CreationService {
  final ApiService _apiService;

  CreationService({ApiService? apiService, String? token}) 
      : _apiService = apiService ?? ApiService(token: token);

  // Mock image picker for now (simplified for Android build)
  Future<File?> pickImageFromCamera() async {
    // Return null for now - this would normally open camera
    // This is simplified to avoid Android build issues
    return null;
  }

  // Mock image picker for now (simplified for Android build)
  Future<File?> pickImageFromGallery() async {
    // Return null for now - this would normally open gallery
    // This is simplified to avoid Android build issues
    return null;
  }

  // Convert an image file to base64
  Future<String> imageFileToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  // Upload an image and analyze it
  Future<Creation> uploadAndAnalyzeImage(File imageFile, Map<String, dynamic> preferences) async {
    try {
      // For web platform or when no image picker, just use mock data
      if (kIsWeb || imageFile == null) {
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
  Future<Creation> generatePoem(int creationId, Map<String, dynamic> poemPreferences) async {
    try {
      final creation = await _apiService.generatePoem(creationId, poemPreferences);
      return creation;
    } catch (e) {
      debugPrint('Error generating poem: $e');
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
