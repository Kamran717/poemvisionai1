import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/poem_generation/domain/models/analysis_result.dart';
import 'package:frontend/features/poem_generation/domain/models/poem.dart';
import 'package:path/path.dart' as path;

/// Poem service
class PoemService {
  /// API client
  final ApiClient _apiClient;
  
  /// Constructor
  PoemService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  
  /// Upload an image for analysis
  Future<String> uploadImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final fileName = path.basename(imagePath);
      final fileExtension = path.extension(imagePath).replaceAll('.', '');
      
      // Create form data
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('image', fileExtension),
        ),
      });
      
      final response = await _apiClient.post(
        '/images/upload',
        data: formData,
      );
      
      return response['image_id'] as String;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Analyze an uploaded image
  Future<AnalysisResult> analyzeImage(String imageId) async {
    try {
      final response = await _apiClient.post(
        '/images/analyze',
        data: {
          'image_id': imageId,
        },
      );
      
      return AnalysisResult.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Generate a poem based on analysis
  Future<Poem> generatePoem({
    required String imageId,
    required String analysisId,
    required String poemType,
    String? customPrompt,
    String? mood,
    String? theme,
  }) async {
    try {
      final data = <String, dynamic>{
        'image_id': imageId,
        'analysis_id': analysisId,
        'poem_type': poemType,
      };
      
      if (customPrompt != null) data['custom_prompt'] = customPrompt;
      if (mood != null) data['mood'] = mood;
      if (theme != null) data['theme'] = theme;
      
      final response = await _apiClient.post(
        '/poems/generate',
        data: data,
      );
      
      return Poem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Edit an existing poem
  Future<Poem> editPoem({
    required String poemId,
    required String title,
    required String content,
  }) async {
    try {
      final response = await _apiClient.put(
        '/poems/$poemId',
        data: {
          'title': title,
          'content': content,
        },
      );
      
      return Poem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Finalize a creation
  Future<String> finalizeCreation({
    required String poemId,
    required String frameType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/creations/finalize',
        data: {
          'poem_id': poemId,
          'frame_type': frameType,
        },
      );
      
      return response['creation_id'] as String;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get poem by ID
  Future<Poem> getPoemById(String poemId) async {
    try {
      final response = await _apiClient.get('/poems/$poemId');
      return Poem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
