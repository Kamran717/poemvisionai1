import 'package:flutter/foundation.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/poem_generation/domain/models/analysis_result.dart';
import 'package:frontend/features/poem_generation/domain/models/poem.dart';
import 'package:frontend/features/poem_generation/domain/services/poem_service.dart';

/// Provider for poem generation functionality
class PoemGenerationProvider extends ChangeNotifier {
  final PoemService _poemService;
  
  // Analysis data
  AnalysisResult? _currentAnalysis;
  AnalysisResult? get currentAnalysis => _currentAnalysis;
  
  // Generated poem
  Poem? _currentPoem;
  Poem? get currentPoem => _currentPoem;
  
  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  PoemGenerationProvider(this._poemService);
  
  /// Load analysis data by ID
  Future<void> loadAnalysisData(String analysisId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // TODO: Replace this with actual API call to get analysis data
      // For now, we'll create mock data
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockAnalysis = AnalysisResult(
        id: analysisId,
        imageUrl: 'https://picsum.photos/800/600',
        detectedElements: [
          'sunset',
          'ocean',
          'beach',
          'palm trees',
          'silhouette',
        ],
        suggestedThemes: [
          'serenity',
          'nature',
          'peace',
          'reflection',
        ],
        emotionScores: {
          'peaceful': 0.85,
          'happy': 0.65,
          'calm': 0.75,
          'nostalgic': 0.40,
        },
        createdAt: DateTime.now(),
      );
      
      _currentAnalysis = mockAnalysis;
      _setLoading(false);
    } catch (e) {
      AppLogger.e('Error loading analysis data', e);
      _setError('Failed to load image analysis data');
    }
  }
  
  /// Generate a poem from analysis data
  Future<Poem> generatePoem({
    required String analysisId,
    required String poemTypeId,
    required String poemLengthId,
    String? tone,
    String? additionalInstructions,
    List<String>? themeWords,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // TODO: Replace with actual API call once backend is integrated
      // For now, create a mock poem
      
      await Future.delayed(const Duration(seconds: 2));
      
      final mockPoem = Poem(
        id: 'poem_${DateTime.now().millisecondsSinceEpoch}',
        content: _generateMockPoemContent(poemTypeId, tone),
        title: 'Sunset Reflections',
        poemType: poemTypeId,
        analysisId: analysisId,
        createdAt: DateTime.now(),
        metadata: {
          'tone': tone,
          'custom_instructions': additionalInstructions,
          'theme_words': themeWords,
        },
        tags: themeWords,
      );
      
      _currentPoem = mockPoem;
      _setLoading(false);
      
      return mockPoem;
    } catch (e) {
      AppLogger.e('Error generating poem', e);
      _setError('Failed to generate poem');
      rethrow;
    }
  }
  
  /// Get a generated poem by ID
  Future<Poem?> getPoemById(String poemId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final poem = await _poemService.getPoemById(poemId);
      
      _currentPoem = poem;
      _setLoading(false);
      
      return poem;
    } catch (e) {
      AppLogger.e('Error getting poem by ID', e);
      _setError('Failed to get poem');
      return null;
    }
  }
  
  /// Save poem edits
  Future<bool> savePoem(Poem poem) async {
    try {
      _setLoading(true);
      _clearError();
      
      final updatedPoem = await _poemService.savePoem(poem);
      
      _currentPoem = updatedPoem;
      _setLoading(false);
      
      return true;
    } catch (e) {
      AppLogger.e('Error saving poem', e);
      _setError('Failed to save poem');
      return false;
    }
  }
  
  /// Share poem publicly
  Future<String?> sharePoemPublic(String poemId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final shareUrl = await _poemService.sharePoemPublic(poemId);
      
      _setLoading(false);
      
      return shareUrl;
    } catch (e) {
      AppLogger.e('Error sharing poem', e);
      _setError('Failed to share poem');
      return null;
    }
  }
  
  /// Regenerate poem with different settings
  Future<Poem?> regeneratePoem({
    required String poemId,
    required String poemTypeId,
    required String poemLengthId,
    String? tone,
    String? additionalInstructions,
    List<String>? themeWords,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final regeneratedPoem = await _poemService.regeneratePoem(
        poemId: poemId,
        poemTypeId: poemTypeId,
        poemLengthId: poemLengthId,
        tone: tone,
        additionalInstructions: additionalInstructions,
        themeWords: themeWords,
      );
      
      _currentPoem = regeneratedPoem;
      _setLoading(false);
      
      return regeneratedPoem;
    } catch (e) {
      AppLogger.e('Error regenerating poem', e);
      _setError('Failed to regenerate poem');
      return null;
    }
  }
  
  /// Edit poem content and title
  Future<bool> editPoem({
    required String poemId,
    required String newContent,
    String? newTitle,
  }) async {
    try {
      if (_currentPoem == null || _currentPoem!.id != poemId) {
        await getPoemById(poemId);
      }
      
      if (_currentPoem == null) {
        throw Exception('Poem not found');
      }
      
      final editedPoem = _currentPoem!.edit(
        newContent: newContent,
        newTitle: newTitle,
      );
      
      return await savePoem(editedPoem);
    } catch (e) {
      AppLogger.e('Error editing poem', e);
      _setError('Failed to edit poem');
      return false;
    }
  }
  
  /// Reset current poem
  void resetCurrentPoem() {
    _currentPoem = null;
    notifyListeners();
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Generate mock poem content for development purposes
  String _generateMockPoemContent(String poemTypeId, String? tone) {
    // Basic mock poems for different types
    if (poemTypeId == 'haiku') {
      return 'Golden sunset glows\n'
          'Ocean waves embrace the shore\n'
          'Peace fills the evening';
    } else if (poemTypeId == 'sonnet') {
      return 'The golden sun descends into the sea,\n'
          'As waves caress the shore with gentle might.\n'
          'The palm trees sway in breeze so wild and free,\n'
          'Their silhouettes stark black against the light.\n\n'
          'The day surrenders to the coming night,\n'
          'As colors paint the sky in rich array.\n'
          'The world transforms before my wond\'ring sight,\n'
          'As nature bids farewell to fading day.\n\n'
          'In moments such as these, I find my peace,\n'
          'A calm reflection on life\'s ebb and flow.\n'
          'The busy thoughts within my mind now cease,\n'
          'As nature\'s beauty sets my soul aglow.\n\n'
          'This sunset scene, a treasure to behold,\n'
          'More precious than the finest gems or gold.';
    } else if (poemTypeId == 'free_verse') {
      return 'The sun\'s final embrace\n'
          'Paints the sky in fiery hues\n'
          'Orange, pink, purple\n'
          'Melting into the horizon.\n\n'
          'Ocean waves, rhythmic and constant\n'
          'Rolling, crashing, retreating\n'
          'A timeless dance with the shore.\n\n'
          'Palm trees stand watch,\n'
          'Silent guardians of this daily ritual,\n'
          'Their silhouettes stark against\n'
          'The canvas of twilight.\n\n'
          'I breathe in the salty air,\n'
          'Let the peace of this moment\n'
          'Wash over me\n'
          'Like the tide over sand.';
    } else {
      // General verse
      return 'As daylight fades across the tranquil sea,\n'
          'The sun descends in glorious array.\n'
          'The sky ablaze with colors bold and free,\n'
          'Marking the passage of another day.\n\n'
          'The palm trees stand like sentinels on shore,\n'
          'Their silhouettes against the fading light.\n'
          'The gentle waves that kiss the sandy floor,\n'
          'Prepare to welcome the approaching night.\n\n'
          'This moment holds a special kind of peace,\n'
          'A calm reflection of life\'s ebb and flow.\n'
          'All worldly troubles temporarily cease,\n'
          'As nature puts on its majestic show.\n';
    }
  }
}
