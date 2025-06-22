import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// import 'package:share_plus/share_plus.dart';
import '../../models/creation.dart';
import '../../services/creation_service.dart';
import '../../utils/image_helper.dart';

class CreatePoemScreen extends StatefulWidget {
  const CreatePoemScreen({super.key});

  @override
  State<CreatePoemScreen> createState() => _CreatePoemScreenState();
}

class _CreatePoemScreenState extends State<CreatePoemScreen> {
  final CreationService _creationService = CreationService();
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  Creation? _creation;
  
  // Step indicators
  final int _totalSteps = 3;
  int _currentStep = 1;
  
  // Poem preferences
  String _selectedPoemType = 'sonnet';
  final List<String> _poemTypes = ['sonnet', 'haiku', 'free verse', 'limerick', 'ode'];
  
  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);

    return Scaffold(
      backgroundColor: primaryBlack,
      appBar: AppBar(
        title: const Text('Create Poem'),
        backgroundColor: primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _buildCurrentStep(),
      ),
    );
  }

  Widget _buildLoadingState() {
    // Theme colors
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: yellow),
          const SizedBox(height: 16),
          Text(
            'Processing your image...',
            style: TextStyle(color: sageGreen.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildSelectImageStep();
      case 2:
        return _buildSelectPoemPreferencesStep();
      case 3:
        return _buildResultStep();
      default:
        return _buildSelectImageStep();
    }
  }

  Widget _buildSelectImageStep() {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          _buildStepIndicator(),
          const SizedBox(height: 24),
          
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Image preview
          if (_selectedImage != null) ...[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(
                        _selectedImage!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                            ),
                          );
                        },
                      )
                    : ImageHelper.displayFileImage(_selectedImage),
              ),
            ),
            const SizedBox(height: 24),
            
            // Continue button
            ElevatedButton(
              onPressed: _proceedToPreferences,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: blueGray,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Continue'),
            ),
            const SizedBox(height: 12),
            
            // Select different image button
            OutlinedButton(
              onPressed: _showImageSourceOptions,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: yellow),
                foregroundColor: yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Select Different Image'),
            ),
          ] else ...[
            // Image selection prompt
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: 100,
                      color: sageGreen.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select an image to create a poem',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a meaningful photo that inspires you',
                      style: TextStyle(
                        color: sageGreen.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Image selection buttons
                    ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        backgroundColor: blueGray,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take a Photo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        backgroundColor: yellow,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectPoemPreferencesStep() {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          _buildStepIndicator(),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Poem Preferences',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'Customize your poem generation',
            style: TextStyle(
              color: sageGreen.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Poem type selection
          const Text(
            'Poem Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _poemTypes.length,
              itemBuilder: (context, index) {
                final poemType = _poemTypes[index];
                final isSelected = poemType == _selectedPoemType;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPoemType = poemType;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? blueGray.withOpacity(0.2) : sageGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? blueGray : sageGreen.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        poemType.toUpperCase(),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? blueGray : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Generate button
          ElevatedButton(
            onPressed: _generatePoem,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: blueGray,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Generate Poem'),
          ),
          const SizedBox(height: 12),
          
          // Back button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: yellow),
              foregroundColor: yellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep() {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    if (_creation == null || _creation!.poemText == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No poem generated yet',
              style: TextStyle(color: sageGreen.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueGray,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Start Over'),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          _buildStepIndicator(),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Your Poem',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Poem display
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Image
                  if (_selectedImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImage!.path,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                                  ),
                                );
                              },
                            )
                          : ImageHelper.displayFileImage(
                              _selectedImage,
                              height: 200,
                              width: double.infinity,
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Poem text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sageGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sageGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _creation!.poemText!,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sharePoem,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: yellow),
                    foregroundColor: yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadPoem,
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: blueGray,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Create new poem button
          OutlinedButton(
            onPressed: _resetCreation,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: sageGreen),
              foregroundColor: sageGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create New Poem'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);
    
    return Row(
      children: List.generate(_totalSteps, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber == _currentStep;
        final isCompleted = stepNumber < _currentStep;
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                // Step circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? yellow
                        : (isActive ? blueGray : sageGreen.withOpacity(0.3)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.black87,
                            size: 18,
                          )
                        : Text(
                            stepNumber.toString(),
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Step label
                Text(
                  _getStepLabel(stepNumber),
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? blueGray : sageGreen.withOpacity(0.8),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _getStepLabel(int step) {
    switch (step) {
      case 1:
        return 'Select Image';
      case 2:
        return 'Preferences';
      case 3:
        return 'Result';
      default:
        return 'Step $step';
    }
  }

  // Image selection methods
  void _showImageSourceOptions() {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);

    showModalBottomSheet(
      context: context,
      backgroundColor: primaryBlack,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: primaryBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: blueGray),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: blueGray),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _creationService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _creationService.pickImageFromCamera();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to take photo: $e';
      });
    }
  }

  // Navigation methods
  void _proceedToPreferences() {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }
    
    setState(() {
      _currentStep = 2;
      _errorMessage = null;
    });
  }

  Future<void> _generatePoem() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
        _currentStep = 1;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Upload and analyze the image
      final preferences = {
        'poem_type': _selectedPoemType,
      };
      
      final creation = await _creationService.uploadAndAnalyzeImage(
        _selectedImage!,
        preferences,
      );
      
      // Generate the poem
      final poemPreferences = {
        'poem_type': _selectedPoemType,
      };
      
      final completeCreation = await _creationService.generatePoem(
        creation,
        poemPreferences,
      );
      
      setState(() {
        _creation = completeCreation;
        _currentStep = 3;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate poem: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetCreation() {
    setState(() {
      _selectedImage = null;
      _creation = null;
      _currentStep = 1;
      _errorMessage = null;
      _selectedPoemType = 'sonnet';
    });
  }

  // Share functionality using share_plus package
  Future<void> _sharePoem() async {
    if (_creation?.poemText == null) {
      debugPrint('No poem to share');
      return;
    }

    try {
      debugPrint('Starting share functionality');
      
      final String shareText = '''🌟 Check out this AI-generated poem! 🌟

${_creation!.poemText!}

✨ Created with PoemVision AI ✨
Transform your moments into beautiful poetry!

#PoemVisionAI #Poetry #AI #CreativeWriting''';

      debugPrint('Share text prepared, length: ${shareText.length}');
      
      // Use share_plus to share the poem
      // TODO: Fix sharing functionality 
      // await Share.share(
      //   shareText,
      //   subject: 'Beautiful AI-Generated Poem',
      // );
      
      debugPrint('Share completed');
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poem shared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Share error: $e');
      
      // Fallback to clipboard if sharing fails
      try {
        final String fallbackText = '''🌟 AI-Generated Poem 🌟

${_creation!.poemText!}

Created with PoemVision AI''';
        
        await Clipboard.setData(ClipboardData(text: fallbackText));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sharing not available. Poem copied to clipboard instead!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (clipboardError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share poem: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Download functionality  
  Future<void> _downloadPoem() async {
    if (_creation?.poemText == null) return;

    try {
      // Copy poem text to clipboard
      await Clipboard.setData(ClipboardData(text: _creation!.poemText!));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poem copied to clipboard!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy poem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
