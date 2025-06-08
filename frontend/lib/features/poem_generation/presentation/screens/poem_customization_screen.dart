import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/presentation/common/app_header.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/services/service_locator.dart';

class PoemCustomizationScreen extends StatefulWidget {
  final String analysisId;
  
  const PoemCustomizationScreen({
    super.key,
    required this.analysisId,
  });

  @override
  State<PoemCustomizationScreen> createState() => _PoemCustomizationScreenState();
}

class _PoemCustomizationScreenState extends State<PoemCustomizationScreen> {
  final ApiClient _apiClient = serviceLocator.get<ApiClient>();
  
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  String? _generatedPoem;
  
  // Analysis results
  List<String> _detectedElements = [];
  
  // User customization options
  String _selectedPoemType = 'general verse';
  String _selectedPoemLength = 'medium';
  List<String> _selectedEmphasis = [];
  String _customPrompt = '';
  
  // Available options
  final List<Map<String, dynamic>> _poemTypes = [
    {'id': 'general verse', 'name': 'General', 'isPremium': false},
    {'id': 'love', 'name': 'Love', 'isPremium': false},
    {'id': 'inspirational', 'name': 'Inspirational', 'isPremium': false},
    {'id': 'funny', 'name': 'Funny', 'isPremium': false},
    {'id': 'haiku', 'name': 'Haiku', 'isPremium': false},
    {'id': 'sonnet', 'name': 'Sonnet', 'isPremium': true},
    {'id': 'memorial', 'name': 'Memorial', 'isPremium': true},
    {'id': 'religious-general', 'name': 'Spiritual', 'isPremium': true},
  ];
  
  final List<Map<String, dynamic>> _poemLengths = [
    {'id': 'short', 'name': 'Short (4-6 lines)', 'isPremium': false},
    {'id': 'medium', 'name': 'Medium (8-12 lines)', 'isPremium': false},
    {'id': 'long', 'name': 'Long (16+ lines)', 'isPremium': true},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadAnalysisResults();
  }
  
  Future<void> _loadAnalysisResults() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      AppLogger.d('Loading analysis results for ID: ${widget.analysisId}');
      
      // TODO: Implement actual API call
      // This is a placeholder until we implement the actual API call
      // In a real implementation, we would fetch the analysis results from the server
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock analysis results
      final mockDetectedElements = [
        'Nature',
        'Mountain',
        'Sunset',
        'Trees',
        'Lake',
        'Reflection',
        'Sky',
        'Clouds',
        'Peace',
        'Tranquility',
      ];
      
      setState(() {
        _isLoading = false;
        _detectedElements = mockDetectedElements;
      });
    } catch (e) {
      AppLogger.e('Error loading analysis results: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load image analysis. Please try again.';
      });
    }
  }
  
  Future<void> _generatePoem() async {
    try {
      setState(() {
        _isGenerating = true;
        _errorMessage = null;
        _generatedPoem = null;
      });
      
      AppLogger.d('Generating poem for analysis ID: ${widget.analysisId}');
      AppLogger.d('Poem type: $_selectedPoemType');
      AppLogger.d('Poem length: $_selectedPoemLength');
      AppLogger.d('Emphasis: $_selectedEmphasis');
      AppLogger.d('Custom prompt: $_customPrompt');
      
      // TODO: Implement actual API call
      // This is a placeholder until we implement the actual API call
      // In a real implementation, we would call:
      // final response = await _apiClient.generatePoem(
      //   analysisId: widget.analysisId,
      //   poemType: _selectedPoemType,
      //   poemLength: _selectedPoemLength,
      //   emphasis: _selectedEmphasis,
      //   customPrompt: _customPrompt.isNotEmpty ? {'terms': _customPrompt} : null,
      // );
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock generated poem
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
        _isGenerating = false;
        _generatedPoem = mockPoem;
      });
    } catch (e) {
      AppLogger.e('Error generating poem: $e');
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Failed to generate poem. Please try again.';
      });
    }
  }
  
  void _toggleEmphasis(String element) {
    setState(() {
      if (_selectedEmphasis.contains(element)) {
        _selectedEmphasis.remove(element);
      } else {
        _selectedEmphasis.add(element);
      }
    });
  }
  
  void _proceedToFinalCreation() {
    AppLogger.d('Proceeding to final creation with analysis ID: ${widget.analysisId}');
    context.go(RoutePaths.getFinalCreationPath(widget.analysisId));
  }
  
  void _regeneratePoem() {
    _generatePoem();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Poem'),
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
            title: 'Customize Your Poem',
            subtitle: 'Personalize how the AI generates your poem',
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
          
          // Elements detected in the image
          _buildDetectedElementsSection(),
          
          const SizedBox(height: 24),
          
          // Poem type selection
          _buildSectionTitle('Poem Type'),
          const SizedBox(height: 8),
          _buildPoemTypeSelector(),
          
          const SizedBox(height: 24),
          
          // Poem length selection
          _buildSectionTitle('Poem Length'),
          const SizedBox(height: 8),
          _buildPoemLengthSelector(),
          
          const SizedBox(height: 24),
          
          // Custom prompt
          _buildSectionTitle('Custom Prompt (Optional)'),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Add specific instructions, names, or themes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                _customPrompt = value;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Generate poem button
          if (_generatedPoem == null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generatePoem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isGenerating
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
                          Text('Generating Poem...'),
                        ],
                      )
                    : const Text('Generate Poem'),
              ),
            ),
          ] else ...[
            // Display generated poem
            _buildGeneratedPoemSection(),
            
            const SizedBox(height: 24),
            
            // Actions for the generated poem
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _regeneratePoem,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _proceedToFinalCreation,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildDetectedElementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Elements Detected'),
            const SizedBox(width: 8),
            Tooltip(
              message: 'These elements were detected in your image. Tap to emphasize them in your poem.',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _detectedElements.map((element) {
            final isSelected = _selectedEmphasis.contains(element);
            return FilterChip(
              label: Text(element),
              selected: isSelected,
              onSelected: (_) => _toggleEmphasis(element),
              backgroundColor: Colors.grey[200],
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildPoemTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _poemTypes.map((type) {
        final isSelected = _selectedPoemType == type['id'];
        final isPremium = type['isPremium'] as bool;
        
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type['name'] as String),
              if (isPremium) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.star,
                  size: 14,
                  color: isSelected ? AppTheme.primaryColor : Colors.amber,
                ),
              ],
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedPoemType = type['id'] as String;
              });
            }
          },
          backgroundColor: Colors.grey[200],
          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildPoemLengthSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _poemLengths.map((length) {
        final isSelected = _selectedPoemLength == length['id'];
        final isPremium = length['isPremium'] as bool;
        
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(length['name'] as String),
              if (isPremium) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.star,
                  size: 14,
                  color: isSelected ? AppTheme.primaryColor : Colors.amber,
                ),
              ],
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedPoemLength = length['id'] as String;
              });
            }
          },
          backgroundColor: Colors.grey[200],
          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildGeneratedPoemSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Poem',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
                    // Copy poem to clipboard
                    AppLogger.d('Copy poem to clipboard');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Poem copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _generatedPoem ?? '',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
