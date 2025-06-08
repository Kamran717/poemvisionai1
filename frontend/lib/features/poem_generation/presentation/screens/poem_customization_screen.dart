import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/features/poem_generation/domain/models/poem_type.dart';
import 'package:frontend/features/poem_generation/domain/models/poem_length.dart';
import 'package:frontend/features/poem_generation/presentation/providers/poem_generation_provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';
import 'package:frontend/presentation/common/app_header.dart';

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
  final _formKey = GlobalKey<FormState>();
  
  String _selectedPoemTypeId = PoemTypes.generalVerse.id;
  String _selectedPoemLengthId = PoemLengths.medium.id;
  String _selectedTone = 'neutral';
  
  final List<String> _availableTones = [
    'neutral',
    'joyful',
    'melancholic',
    'romantic',
    'nostalgic',
    'inspirational',
    'mysterious',
  ];
  
  final _instructionsController = TextEditingController();
  final _themeWordsController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPremiumUser = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _instructionsController.dispose();
    _themeWordsController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if user has premium
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null && user['isPremium'] == true) {
        setState(() {
          _isPremiumUser = true;
        });
      }
      
      // Load analysis data
      final poemProvider = Provider.of<PoemGenerationProvider>(context, listen: false);
      await poemProvider.loadAnalysisData(widget.analysisId);
      
      // Set theme words from analysis if available
      final analysis = poemProvider.currentAnalysis;
      if (analysis != null && analysis.suggestedThemes.isNotEmpty) {
        setState(() {
          _themeWordsController.text = analysis.suggestedThemes.join(', ');
        });
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading data', e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load image analysis data';
      });
    }
  }
  
  Future<void> _generatePoem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Process theme words
      List<String>? themeWords;
      if (_themeWordsController.text.isNotEmpty) {
        themeWords = _themeWordsController.text
            .split(',')
            .map((word) => word.trim())
            .where((word) => word.isNotEmpty)
            .toList();
      }
      
      // Generate the poem
      final poemProvider = Provider.of<PoemGenerationProvider>(context, listen: false);
      final poem = await poemProvider.generatePoem(
        analysisId: widget.analysisId,
        poemTypeId: _selectedPoemTypeId,
        poemLengthId: _selectedPoemLengthId,
        tone: _selectedTone,
        additionalInstructions: _instructionsController.text.isEmpty 
            ? null 
            : _instructionsController.text,
        themeWords: themeWords,
      );
      
      if (mounted) {
        // Navigate to the final creation screen
        context.go('${RoutePaths.finalCreation}/${widget.analysisId}');
      }
    } catch (e) {
      AppLogger.e('Error generating poem', e);
      setState(() {
        _errorMessage = 'Failed to generate poem. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Your Poem'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Image upload index
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
  
  Widget _buildContent() {
    final poemProvider = Provider.of<PoemGenerationProvider>(context);
    final analysis = poemProvider.currentAnalysis;
    
    if (analysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load image analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again or upload a new image',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.imageUpload),
              child: const Text('Upload New Image'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analysis summary
            _buildAnalysisSummary(analysis),
            
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
            
            // Poem Type Selection
            const Text(
              'Poem Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildPoemTypeSelection(),
            
            const SizedBox(height: 24),
            
            // Poem Length Selection
            const Text(
              'Poem Length',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildPoemLengthSelection(),
            
            const SizedBox(height: 24),
            
            // Tone Selection
            const Text(
              'Tone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildToneSelection(),
            
            const SizedBox(height: 24),
            
            // Theme Words
            const Text(
              'Theme Words (comma separated)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _themeWordsController,
              decoration: InputDecoration(
                hintText: 'e.g., nature, love, friendship',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // Additional Instructions
            const Text(
              'Additional Instructions (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _instructionsController,
              decoration: InputDecoration(
                hintText: 'Any specific requests for the poem',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            
            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generatePoem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
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
                          Text('Generating...'),
                        ],
                      )
                    : const Text(
                        'Generate Poem',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Premium upgrade prompt if not premium
            if (!_isPremiumUser) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Unlock all poem types, longer poems, and more customization options!',
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to premium upgrade screen
                        },
                        child: const Text('Learn More'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalysisSummary(AnalysisResult analysis) {
    final dominantEmotion = analysis.getDominantEmotion();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    analysis.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Image Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dominant emotion: ${dominantEmotion.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${analysis.detectedElements.length} elements detected',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (analysis.detectedElements.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Detected Elements:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: analysis.detectedElements.map((element) {
                  return Chip(
                    label: Text(element),
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPoemTypeSelection() {
    final allTypes = PoemTypes.getAll();
    
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allTypes.map((type) {
            final isSelected = _selectedPoemTypeId == type.id;
            final isPremium = type.isPremium;
            final isDisabled = isPremium && !_isPremiumUser;
            
            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      setState(() {
                        _selectedPoemTypeId = type.id;
                      });
                    },
              child: Container(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          type.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDisabled ? Colors.grey : null,
                          ),
                        ),
                        if (isPremium)
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDisabled ? Colors.grey : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isDisabled) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Premium only',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildPoemLengthSelection() {
    final allLengths = PoemLengths.getAll();
    
    return Column(
      children: [
        Row(
          children: allLengths.map((length) {
            final isSelected = _selectedPoemLengthId == length.id;
            final isPremium = length.isPremium;
            final isDisabled = isPremium && !_isPremiumUser;
            
            return Expanded(
              child: GestureDetector(
                onTap: isDisabled
                    ? null
                    : () {
                        setState(() {
                          _selectedPoemLengthId = length.id;
                        });
                      },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            length.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDisabled ? Colors.grey : null,
                            ),
                          ),
                          if (isPremium) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${length.minLines}-${length.maxLines} lines',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDisabled ? Colors.grey : Colors.grey[700],
                        ),
                      ),
                      if (isDisabled) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Premium only',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildToneSelection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _availableTones.map((tone) {
          final isSelected = _selectedTone == tone;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tone.capitalize()),
              selected: isSelected,
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryColor.withOpacity(0.1),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTone = tone;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Helper extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
