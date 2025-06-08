import 'package:flutter/foundation.dart';
import 'package:frontend/features/poem_generation/domain/models/analysis_result.dart';
import 'package:frontend/features/poem_generation/domain/models/poem.dart';
import 'package:frontend/features/poem_generation/domain/services/poem_service.dart';

/// Poem generation provider
class PoemGenerationProvider extends ChangeNotifier {
  /// Poem service
  final PoemService _poemService;
  
  /// Current uploaded image ID
  String? _uploadedImageId;
  
  /// Current image analysis result
  AnalysisResult? _analysisResult;
  
  /// Current generated poem
  Poem? _generatedPoem;
  
  /// Selected frame type
  String _selectedFrameType = 'classic';
  
  /// Loading state
  bool _isLoading = false;
  
  /// Error message
  String? _errorMessage;
  
  /// Constructor
  PoemGenerationProvider({
    required PoemService poemService,
  }) : _poemService = poemService;
  
  /// Get current uploaded image ID
  String? get uploadedImageId => _uploadedImageId;
  
  /// Get current image analysis result
  AnalysisResult? get analysisResult => _analysisResult;
  
  /// Get current generated poem
  Poem? get generatedPoem => _generatedPoem;
  
  /// Get selected frame type
  String get selectedFrameType => _selectedFrameType;
  
  /// Get loading state
  bool get isLoading => _isLoading;
  
  /// Get error message
  String? get errorMessage => _errorMessage;
  
  /// Upload an image
  Future<bool> uploadImage(String imagePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final imageId = await _poemService.uploadImage(imagePath);
      _uploadedImageId = imageId;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Analyze uploaded image
  Future<bool> analyzeImage() async {
    if (_uploadedImageId == null) {
      _errorMessage = 'No image uploaded';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await _poemService.analyzeImage(_uploadedImageId!);
      _analysisResult = result;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Generate poem based on analysis
  Future<bool> generatePoem({
    required String poemType,
    String? customPrompt,
    String? mood,
    String? theme,
  }) async {
    if (_analysisResult == null) {
      _errorMessage = 'No image analysis available';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final poem = await _poemService.generatePoem(
        imageId: _uploadedImageId!,
        analysisId: _analysisResult!.id,
        poemType: poemType,
        customPrompt: customPrompt,
        mood: mood,
        theme: theme,
      );
      
      _generatedPoem = poem;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Edit generated poem
  Future<bool> editPoem({
    required String newTitle,
    required String newContent,
  }) async {
    if (_generatedPoem == null) {
      _errorMessage = 'No poem to edit';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final editedPoem = await _poemService.editPoem(
        poemId: _generatedPoem!.id,
        title: newTitle,
        content: newContent,
      );
      
      _generatedPoem = editedPoem;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Set selected frame type
  void setFrameType(String frameType) {
    _selectedFrameType = frameType;
    notifyListeners();
  }
  
  /// Finalize creation
  Future<String?> finalizeCreation() async {
    if (_generatedPoem == null) {
      _errorMessage = 'No poem to finalize';
      notifyListeners();
      return null;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final creationId = await _poemService.finalizeCreation(
        poemId: _generatedPoem!.id,
        frameType: _selectedFrameType,
      );
      
      _isLoading = false;
      notifyListeners();
      
      // Clear state after finalization
      _reset();
      
      return creationId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Reset state
  void _reset() {
    _uploadedImageId = null;
    _analysisResult = null;
    _generatedPoem = null;
    _selectedFrameType = 'classic';
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Clear state
  void clear() {
    _reset();
  }
}
