import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';

/// Screen for customizing poem generation
class PoemCustomizationScreen extends StatefulWidget {
  /// Image ID for poem generation
  final String imageId;
  
  /// Analysis ID for poem generation
  final String analysisId;
  
  /// Constructor
  const PoemCustomizationScreen({
    super.key,
    required this.imageId,
    required this.analysisId,
  });

  @override
  State<PoemCustomizationScreen> createState() => _PoemCustomizationScreenState();
}

class _PoemCustomizationScreenState extends State<PoemCustomizationScreen> {
  final List<String> _poemTypes = [
    'Sonnet',
    'Haiku',
    'Free Verse',
    'Limerick',
    'Acrostic',
  ];
  
  String _selectedPoemType = 'Sonnet';
  String _mood = 'Reflective';
  bool _isGenerating = false;
  
  final _customPromptController = TextEditingController();
  
  @override
  void dispose() {
    _customPromptController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Your Poem'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder for image preview
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Poem type selector
              const Text(
                'Select Poem Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                children: _poemTypes.map((type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: _selectedPoemType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPoemType = type;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Mood selector
              const Text(
                'Mood',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              DropdownButtonFormField<String>(
                value: _mood,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Joyful', child: Text('Joyful')),
                  DropdownMenuItem(value: 'Reflective', child: Text('Reflective')),
                  DropdownMenuItem(value: 'Melancholic', child: Text('Melancholic')),
                  DropdownMenuItem(value: 'Inspirational', child: Text('Inspirational')),
                  DropdownMenuItem(value: 'Serene', child: Text('Serene')),
                  DropdownMenuItem(value: 'Mysterious', child: Text('Mysterious')),
                ],
                onChanged: (value) {
                  setState(() {
                    _mood = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Custom prompt
              const Text(
                'Custom Prompt (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              TextField(
                controller: _customPromptController,
                decoration: const InputDecoration(
                  hintText: 'Add specific themes or elements to include...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // Generate button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generatePoem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isGenerating
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Generate Poem',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _generatePoem() {
    setState(() {
      _isGenerating = true;
    });
    
    // Simulate poem generation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        
        // Navigate to final creation with mock poem ID
        context.go(
          '${RoutePaths.finalCreation}?poem_id=mockPoemId789'
        );
      }
    });
  }
}
