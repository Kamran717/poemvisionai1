import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Poem'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _buildCurrentStep(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing your image...'),
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
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
            const SizedBox(height: 12),
            
            // Select different image button
            OutlinedButton(
              onPressed: _showImageSourceOptions,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                    const Icon(
                      Icons.image,
                      size: 100,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select an image to create a poem',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a meaningful photo that inspires you',
                      style: TextStyle(
                        color: Colors.grey,
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
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
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          const Text(
            'Customize your poem generation',
            style: TextStyle(
              color: Colors.grey,
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
                      color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        poemType.toUpperCase(),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue : Colors.black,
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
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
            ),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep() {
    if (_creation == null || _creation!.poemText == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No poem generated yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
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
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _creation!.poemText!,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
            ),
            child: const Text('Create New Poem'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
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
                        ? Colors.green
                        : (isActive ? Colors.blue : Colors.grey.withOpacity(0.3)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            stepNumber.toString(),
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black54,
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
                    color: isActive ? Colors.blue : Colors.black54,
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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
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

  // Share functionality (temporarily using clipboard until share_plus is working)
  Future<void> _sharePoem() async {
    if (_creation?.poemText == null) {
      print('DEBUG: No poem to share');
      return;
    }

    try {
      print('DEBUG: Starting share functionality');
      
      final String shareText = '''🌟 Check out this AI-generated poem! 🌟

${_creation!.poemText!}

Created with PoemVision AI
#poetry #AI #creativity''';

      print('DEBUG: Share text prepared, length: ${shareText.length}');
      
      // Copy to clipboard as temporary share functionality
      await Clipboard.setData(ClipboardData(text: shareText));
      
      print('DEBUG: Share completed successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poem copied to clipboard! You can now paste it to share.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Share error: $e');
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
