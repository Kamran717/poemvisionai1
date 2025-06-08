import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';

/// Screen for final poem creation and framing
class FinalCreationScreen extends StatefulWidget {
  /// Poem ID for displaying the poem
  final String poemId;
  
  /// Shared ID for shared poems
  final String? sharedId;
  
  /// Whether this is a shared poem view
  final bool isShared;
  
  /// Constructor
  const FinalCreationScreen({
    super.key,
    this.poemId = '',
    this.sharedId,
    this.isShared = false,
  });

  @override
  State<FinalCreationScreen> createState() => _FinalCreationScreenState();
}

class _FinalCreationScreenState extends State<FinalCreationScreen> {
  final List<String> _frameTypes = [
    'classic',
    'elegant',
    'minimalist',
    'vintage',
    'modern',
  ];
  
  String _selectedFrameType = 'classic';
  bool _isSaving = false;
  
  // Mock poem data
  final Map<String, dynamic> _mockPoem = {
    'title': 'Autumn Reflections',
    'content': '''
As golden leaves drift down in grace,
A symphony of color takes its place.
The wind, a gentle whisper through the trees,
Carrying memories on autumn's breeze.

Nature paints her canvas, bold and bright,
Before the coming of winter's night.
Each moment captured in this fleeting scene,
A testament to what has been.

Time passes like the seasons' flow,
Reminding us of all we know.
That beauty lives in change and in decay,
As autumn guides us on our way.
''',
    'poemType': 'Sonnet',
  };
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Poem'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Poem display with frame
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Poem title
                      Text(
                        _mockPoem['title'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Playfair Display',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Poem content
                      Text(
                        _mockPoem['content'],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          fontFamily: 'Playfair Display',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Poem type
                      Text(
                        _mockPoem['poemType'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textLightColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Frame selector
              if (!widget.isShared) ...[
                const Text(
                  'Select Frame',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _frameTypes.length,
                    itemBuilder: (context, index) {
                      final frameType = _frameTypes[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFrameType = frameType;
                            });
                          },
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedFrameType == frameType
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300]!,
                                width: _selectedFrameType == frameType ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                frameType.substring(0, 1).toUpperCase() +
                                    frameType.substring(1),
                                style: TextStyle(
                                  color: _selectedFrameType == frameType
                                      ? AppTheme.primaryColor
                                      : AppTheme.textDarkColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                
                // Save/Share buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveCreation,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _shareCreation,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Shared view actions
                ElevatedButton.icon(
                  onPressed: () => context.go(RoutePaths.home),
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Home'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _saveCreation() {
    setState(() {
      _isSaving = true;
    });
    
    // Simulate saving delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poem saved successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Navigate to gallery
        context.go(RoutePaths.gallery);
      }
    });
  }
  
  void _shareCreation() {
    // Show sharing options dialog
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Your Creation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard!'),
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Export as Image'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exporting as image...'),
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.social_distance),
                title: const Text('Share to Social Media'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening social media options...'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
