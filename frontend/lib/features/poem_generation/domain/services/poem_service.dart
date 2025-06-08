import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/poem_generation/domain/models/analysis_result.dart';
import 'package:frontend/features/poem_generation/domain/models/poem.dart';
import 'package:frontend/features/poem_generation/domain/models/poem_length.dart';
import 'package:frontend/features/poem_generation/domain/models/poem_type.dart';

/// Service for handling poem generation and management
class PoemService {
  final ApiClient _apiClient;

  PoemService(this._apiClient);

  /// Generate a poem from an image analysis
  Future<Poem> generatePoem({
    required String analysisId,
    required String poemTypeId,
    required String poemLengthId,
    String? tone,
    String? additionalInstructions,
    List<String>? themeWords,
  }) async {
    try {
      AppLogger.d('Generating poem for analysis: $analysisId');
      
      final response = await _apiClient.post(
        '/api/poems/generate',
        data: {
          'analysis_id': analysisId,
          'poem_type': poemTypeId,
          'poem_length': poemLengthId,
          'tone': tone,
          'additional_instructions': additionalInstructions,
          'theme_words': themeWords,
        },
      );
      
      if (response.isSuccess && response.data != null) {
        final poemData = response.data!;
        return Poem.fromJson(poemData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to generate poem');
      }
    } catch (e) {
      AppLogger.e('Error generating poem', e);
      rethrow;
    }
  }

  /// Get a specific poem by ID
  Future<Poem> getPoemById(String poemId) async {
    try {
      AppLogger.d('Getting poem by ID: $poemId');
      
      final response = await _apiClient.get('/api/poems/$poemId');
      
      if (response.isSuccess && response.data != null) {
        final poemData = response.data!;
        return Poem.fromJson(poemData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to get poem');
      }
    } catch (e) {
      AppLogger.e('Error getting poem', e);
      rethrow;
    }
  }

  /// Get all poems for a user
  Future<List<Poem>> getUserPoems() async {
    try {
      AppLogger.d('Getting all user poems');
      
      final response = await _apiClient.get('/api/poems');
      
      if (response.isSuccess && response.data != null) {
        final poemsData = response.data! as List<dynamic>;
        return poemsData.map((data) => Poem.fromJson(data)).toList();
      } else {
        throw Exception(response.error?.message ?? 'Failed to get user poems');
      }
    } catch (e) {
      AppLogger.e('Error getting user poems', e);
      rethrow;
    }
  }

  /// Save or update a poem
  Future<Poem> savePoem(Poem poem) async {
    try {
      AppLogger.d('Saving poem: ${poem.id}');
      
      final response = await _apiClient.put(
        '/api/poems/${poem.id}',
        data: poem.toJson(),
      );
      
      if (response.isSuccess && response.data != null) {
        final updatedPoemData = response.data!;
        return Poem.fromJson(updatedPoemData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to save poem');
      }
    } catch (e) {
      AppLogger.e('Error saving poem', e);
      rethrow;
    }
  }

  /// Delete a poem
  Future<bool> deletePoem(String poemId) async {
    try {
      AppLogger.d('Deleting poem: $poemId');
      
      final response = await _apiClient.delete('/api/poems/$poemId');
      
      return response.isSuccess;
    } catch (e) {
      AppLogger.e('Error deleting poem', e);
      rethrow;
    }
  }

  /// Share a poem with a public link
  Future<String> sharePoemPublic(String poemId) async {
    try {
      AppLogger.d('Sharing poem: $poemId');
      
      final response = await _apiClient.post(
        '/api/poems/$poemId/share',
        data: {'public': true},
      );
      
      if (response.isSuccess && response.data != null) {
        final shareData = response.data!;
        return shareData['share_url'] as String;
      } else {
        throw Exception(response.error?.message ?? 'Failed to share poem');
      }
    } catch (e) {
      AppLogger.e('Error sharing poem', e);
      rethrow;
    }
  }

  /// Get all available poem types
  Future<List<PoemType>> getPoemTypes() async {
    try {
      AppLogger.d('Getting all poem types');
      
      final response = await _apiClient.get('/api/poem-types');
      
      if (response.isSuccess && response.data != null) {
        final typesData = response.data! as List<dynamic>;
        return typesData.map((data) => PoemType.fromJson(data)).toList();
      } else {
        // If API fails, return the predefined types
        return PoemTypes.getAll();
      }
    } catch (e) {
      AppLogger.e('Error getting poem types', e);
      // If there's an error, return the predefined types
      return PoemTypes.getAll();
    }
  }

  /// Get poem by analysis ID
  Future<List<Poem>> getPoemsByAnalysisId(String analysisId) async {
    try {
      AppLogger.d('Getting poems for analysis: $analysisId');
      
      final response = await _apiClient.get('/api/poems/by-analysis/$analysisId');
      
      if (response.isSuccess && response.data != null) {
        final poemsData = response.data! as List<dynamic>;
        return poemsData.map((data) => Poem.fromJson(data)).toList();
      } else {
        throw Exception(response.error?.message ?? 'Failed to get poems by analysis');
      }
    } catch (e) {
      AppLogger.e('Error getting poems by analysis', e);
      rethrow;
    }
  }

  /// Regenerate a poem with different settings
  Future<Poem> regeneratePoem({
    required String poemId,
    required String poemTypeId,
    required String poemLengthId,
    String? tone,
    String? additionalInstructions,
    List<String>? themeWords,
  }) async {
    try {
      AppLogger.d('Regenerating poem: $poemId');
      
      final response = await _apiClient.post(
        '/api/poems/$poemId/regenerate',
        data: {
          'poem_type': poemTypeId,
          'poem_length': poemLengthId,
          'tone': tone,
          'additional_instructions': additionalInstructions,
          'theme_words': themeWords,
        },
      );
      
      if (response.isSuccess && response.data != null) {
        final poemData = response.data!;
        return Poem.fromJson(poemData);
      } else {
        throw Exception(response.error?.message ?? 'Failed to regenerate poem');
      }
    } catch (e) {
      AppLogger.e('Error regenerating poem', e);
      rethrow;
    }
  }
}
