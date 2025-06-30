import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
// import 'package:share_plus/share_plus.dart';
import '../../models/creation.dart';
import '../../models/poem_type.dart';
import '../../models/personalization_data.dart';
import '../../models/frame.dart';
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
  final int _totalSteps = 5;
  int _currentStep = 1;
  
  // Poem preferences
  PoemType _selectedPoemType = PoemTypeData.allPoemTypes.first;
  List<PoemType> _availablePoemTypes = [];
  bool _isPremium = false; // TODO: Get from user service
  
  // Frame selection
  Frame _selectedFrame = FrameData.availableFrames.first;
  List<Frame> _availableFrames = [];
  
  // Personalization data
  PersonalizationData _personalizationData = PersonalizationData();
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _customMessageController = TextEditingController();
  String? _selectedRelationship;
  String? _selectedEmotion;
  
  @override
  void initState() {
    super.initState();
    _loadAvailablePoemTypes();
  }
  
  void _loadAvailablePoemTypes() {
    setState(() {
      // Load ALL poem types (both free and premium)
      _availablePoemTypes = PoemTypeData.allPoemTypes;
      // Set default to general verse if available, otherwise first free type
      final generalVerse = _availablePoemTypes.firstWhere(
        (type) => type.id == 'general verse',
        orElse: () => PoemTypeData.getFreePoemTypes().first,
      );
      _selectedPoemType = generalVerse;
      
      // Load available frames
      _availableFrames = FrameData.getAvailableFrames(_isPremium);
      _selectedFrame = _availableFrames.first;
    });
  }
  
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
            'Processing your creation...',
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
        return _buildPersonalizationStep();
      case 4:
        return _buildFrameSelectionStep();
      case 5:
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
            child: _availablePoemTypes.isEmpty
                ? Center(
                    child: Text(
                      'Loading poem types...',
                      style: TextStyle(color: sageGreen.withOpacity(0.8)),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _availablePoemTypes.length,
                    itemBuilder: (context, index) {
                      final poemType = _availablePoemTypes[index];
                      final isSelected = poemType.id == _selectedPoemType.id;
                      final isPremiumLocked = !poemType.free && !_isPremium;
                      
                      return GestureDetector(
                        onTap: isPremiumLocked
                            ? () => _showPremiumRequiredDialog()
                            : () {
                                setState(() {
                                  _selectedPoemType = poemType;
                                });
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? blueGray.withOpacity(0.2) 
                                : isPremiumLocked 
                                  ? Colors.grey.withOpacity(0.1)
                                  : sageGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? blueGray 
                                  : isPremiumLocked
                                    ? Colors.grey.withOpacity(0.3)
                                    : sageGreen.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    poemType.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected 
                                          ? blueGray 
                                          : isPremiumLocked
                                            ? Colors.grey
                                            : Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (isPremiumLocked)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(
                                    Icons.lock,
                                    size: 16,
                                    color: yellow,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Continue to personalization button
          ElevatedButton(
            onPressed: _proceedToPersonalization,
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

  Widget _buildPersonalizationStep() {
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
            'Make It Personal',
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
            'Add personal details to create a meaningful poem',
            style: TextStyle(
              color: sageGreen.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Optional notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: yellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: yellow.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: yellow, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All fields are optional. Skip to generate poem.',
                    style: TextStyle(
                      color: yellow,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Form fields
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Person's name
                  const Text(
                    'Person\'s Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _personNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., Sarah, Mom, my best friend',
                      hintStyle: TextStyle(color: sageGreen.withOpacity(0.7)),
                      filled: true,
                      fillColor: sageGreen.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: blueGray),
                      ),
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  
                  // Relationship dropdown
                  const Text(
                    'Relationship',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedRelationship,
                    onChanged: (value) {
                      setState(() {
                        _selectedRelationship = value;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF1B2A37),
                    decoration: InputDecoration(
                      hintText: 'Select relationship',
                      hintStyle: TextStyle(color: sageGreen.withOpacity(0.7)),
                      filled: true,
                      fillColor: sageGreen.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: blueGray),
                      ),
                    ),
                    items: PersonalizationOptions.relationships.map((relationship) {
                      return DropdownMenuItem<String>(
                        value: relationship,
                        child: Text(relationship),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Occasion
                  const Text(
                    'Special Occasion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _occasionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., Birthday, Anniversary, Graduation',
                      hintStyle: TextStyle(color: sageGreen.withOpacity(0.7)),
                      filled: true,
                      fillColor: sageGreen.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: blueGray),
                      ),
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  
                  // Emotion dropdown
                  const Text(
                    'Emotion/Mood',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedEmotion,
                    onChanged: (value) {
                      setState(() {
                        _selectedEmotion = value;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF1B2A37),
                    decoration: InputDecoration(
                      hintText: 'Select emotion',
                      hintStyle: TextStyle(color: sageGreen.withOpacity(0.7)),
                      filled: true,
                      fillColor: sageGreen.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: blueGray),
                      ),
                    ),
                    items: PersonalizationOptions.emotions.map((emotion) {
                      return DropdownMenuItem<String>(
                        value: emotion,
                        child: Text(emotion),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Custom message
                  const Text(
                    'Additional Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customMessageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Any special memories, qualities, or details to include...',
                      hintStyle: TextStyle(color: sageGreen.withOpacity(0.7)),
                      filled: true,
                      fillColor: sageGreen.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: blueGray),
                      ),
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Generate poem button
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
          
          // Skip personalization button
          OutlinedButton(
            onPressed: _skipPersonalizationAndGenerate,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: yellow),
              foregroundColor: yellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Skip & Generate'),
          ),
          const SizedBox(height: 12),
          
          // Back button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _currentStep = 2;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: sageGreen),
              foregroundColor: sageGreen,
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

  Widget _buildFrameSelectionStep() {
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
            'Choose Frame Style',
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
            'Select a beautiful frame for your poem',
            style: TextStyle(
              color: sageGreen.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Frame selection
          Expanded(
            child: _availableFrames.isEmpty
                ? Center(
                    child: Text(
                      'Loading frames...',
                      style: TextStyle(color: sageGreen.withOpacity(0.8)),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _availableFrames.length,
                    itemBuilder: (context, index) {
                      final frame = _availableFrames[index];
                      final isSelected = frame.id == _selectedFrame.id;
                      final isPremiumLocked = frame.isPremium && !_isPremium;
                      
                      return GestureDetector(
                        onTap: isPremiumLocked
                            ? () => _showPremiumRequiredDialog()
                            : () {
                                setState(() {
                                  _selectedFrame = frame;
                                });
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? blueGray.withOpacity(0.2) 
                                : isPremiumLocked 
                                  ? Colors.grey.withOpacity(0.1)
                                  : sageGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? blueGray 
                                  : isPremiumLocked
                                    ? Colors.grey.withOpacity(0.3)
                                    : sageGreen.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Frame preview (using asset image with error handling)
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: sageGreen.withOpacity(0.1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          frame.assetPath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            // Fallback UI if frame image fails to load
                                            return Container(
                                              color: sageGreen.withOpacity(0.2),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.image_outlined,
                                                      color: sageGreen,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      frame.name,
                                                      style: TextStyle(
                                                        color: sageGreen,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Frame name
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      frame.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected 
                                            ? blueGray 
                                            : isPremiumLocked
                                              ? Colors.grey
                                              : Colors.white,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (isPremiumLocked)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(
                                    Icons.lock,
                                    size: 16,
                                    color: yellow,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Create final image button
          ElevatedButton(
            onPressed: _createFinalImage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: blueGray,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create Final Poem'),
          ),
          const SizedBox(height: 12),
          
          // Back button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _currentStep = 3;
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          _buildStepIndicator(),
          const SizedBox(height: 24),
          
          // Success message
          const Text(
            'Your Poem is Ready!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Final result display
          Expanded(
            child: _creation?.finalImageData != null
                ? Column(
                    children: [
                      // Final framed image
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            CreationService.base64ToImage(_creation!.finalImageData!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // Original image
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedImage != null
                              ? (kIsWeb
                                  ? Image.network(
                                      _selectedImage!.path,
                                      fit: BoxFit.cover,
                                    )
                                  : ImageHelper.displayFileImage(_selectedImage))
                              : Container(
                                  color: sageGreen.withOpacity(0.1),
                                  child: Icon(
                                    Icons.image,
                                    size: 100,
                                    color: sageGreen.withOpacity(0.5),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Poem text
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: sageGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sageGreen.withOpacity(0.3)),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _creation?.poemText ?? 'Your poem will appear here...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sharePoem,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: blueGray,
                    foregroundColor: Colors.white,
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: yellow,
                    foregroundColor: Colors.black87,
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
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < _currentStep;
        final isActive = stepNumber == _currentStep;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isActive
                    ? yellow
                    : sageGreen.withOpacity(0.3),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.black87, size: 16)
                    : Text(
                        stepNumber.toString(),
                        style: TextStyle(
                          color: isActive ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            if (index < _totalSteps - 1) ...[
              const SizedBox(width: 4),
              Container(
                width: 20,
                height: 2,
                color: stepNumber < _currentStep
                    ? yellow
                    : sageGreen.withOpacity(0.3),
              ),
              const SizedBox(width: 4),
            ],
          ],
        );
      }),
    );
  }

  String _getStepLabel(int step) {
    switch (step) {
      case 1:
        return 'Image';
      case 2:
        return 'Poem';
      case 3:
        return 'Personal';
      case 4:
        return 'Frame';
      case 5:
        return 'Result';
      default:
        return 'Step $step';
    }
  }

  // Navigation methods
  void _proceedToPreferences() {
    setState(() {
      _currentStep = 2;
    });
  }

  void _proceedToPersonalization() {
    setState(() {
      _currentStep = 3;
    });
  }

  // Image picker methods
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2A37),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final imageFile = await _creationService.pickImageFromGallery();
      if (imageFile != null) {
        setState(() {
          _selectedImage = imageFile;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showPermissionDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final imageFile = await _creationService.pickImageFromCamera();
      if (imageFile != null) {
        setState(() {
          _selectedImage = imageFile;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showPermissionDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Poem generation methods
  Future<void> _generatePoem() async {
    _clearPersonalizationData();
    await _generatePoemWithData();
  }

  Future<void> _skipPersonalizationAndGenerate() async {
    await _generatePoemWithData();
  }

  void _clearPersonalizationData() {
    _personalizationData = PersonalizationData(
      personName: _personNameController.text.trim(),
      relationship: _selectedRelationship,
      occasion: _occasionController.text.trim(),
      location: _locationController.text.trim(),
      emotion: _selectedEmotion,
      customMessage: _customMessageController.text.trim(),
    );
  }

  Future<void> _generatePoemWithData() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // First upload and analyze image
      final uploadedCreation = await _creationService.uploadAndAnalyzeImage(
        _selectedImage!,
        {},
      );

      // Then generate poem
      final poemPreferences = {
        'poem_type': _selectedPoemType.id,
        'poem_length': 'medium',
        'emphasis': [],
        'custom_prompt': _personalizationData.toCustomPrompt(),
      };

      final poemCreation = await _creationService.generatePoem(
        uploadedCreation,
        poemPreferences,
      );

      setState(() {
        _creation = poemCreation;
        _currentStep = 4; // Move to frame selection
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createFinalImage() async {
    if (_creation == null) {
      setState(() {
        _errorMessage = 'No poem found to create final image';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final finalCreation = await _creationService.createFinalImage(
        _creation!,
        _selectedFrame.id,
      );

      setState(() {
        _creation = finalCreation;
        _currentStep = 5; // Move to result
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Result actions
  void _sharePoem() {
    if (_creation?.shareCode != null) {
      // TODO: Implement sharing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share functionality coming soon!')),
      );
    }
  }

  void _downloadPoem() {
    if (_creation?.finalImageData != null) {
      // TODO: Implement download
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download functionality coming soon!')),
      );
    }
  }

  void _resetCreation() {
    setState(() {
      _currentStep = 1;
      _selectedImage = null;
      _creation = null;
      _errorMessage = null;
      _personNameController.clear();
      _occasionController.clear();
      _locationController.clear();
      _customMessageController.clear();
      _selectedRelationship = null;
      _selectedEmotion = null;
    });
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Required'),
        content: const Text('This feature requires a premium membership. Upgrade to unlock all poem types and frames.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/upgrade');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _occasionController.dispose();
    _locationController.dispose();
    _customMessageController.dispose();
    super.dispose();
  }
}
