import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/features/poem_generation/domain/models/poem.dart';
import 'package:frontend/features/poem_generation/presentation/providers/poem_generation_provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';

class FinalCreationScreen extends StatefulWidget {
  final String analysisId;

  const FinalCreationScreen({
    super.key,
    required this.analysisId,
  });

  @override
  State<FinalCreationScreen> createState() => _FinalCreationScreenState();
}

class _FinalCreationScreenState extends State<FinalCreationScreen> {
  final _poemController = TextEditingController();
  final _titleController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isSharing = false;
  String? _errorMessage;
  
  int _selectedFrameIndex = 0;
  
  // Sample frames for demonstration
  final List<_FrameOption> _frames = [
    _FrameOption(
      name: 'Classic',
      assetPath: 'assets/frames/classic.jpg',
      isPremium: false,
    ),
    _FrameOption(
      name: 'Elegant',
      assetPath: 'assets/frames/elegant.jpg',
      isPremium: false,
    ),
    _FrameOption(
      name: 'Minimalist',
      assetPath: 'assets/frames/minimalist.jpg',
      isPremium: false,
    ),
    _FrameOption(
      name: 'Vintage',
      assetPath: 'assets/frames/vintage.jpg',
      isPremium: true,
    ),
    _FrameOption(
      name: 'Ornate',
      assetPath: 'assets/frames/ornate.jpg',
      isPremium: true,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _loadPoem();
  }
  
  @override
  void dispose() {
    _poemController.dispose();
    _titleController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPoem() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final poemProvider = Provider.of<PoemGenerationProvider>(context, listen: false);
      final poem = poemProvider.currentPoem;
      
      if (poem != null) {
        _poemController.text = poem.content;
        _titleController.text = poem.title;
      } else {
        // If no poem in provider, we need to generate one or get from server
        AppLogger.d('No poem found, redirecting to customization screen');
        if (mounted) {
          context.go('${RoutePaths.poemCustomization}/${widget.analysisId}');
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading poem', e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load poem';
      });
    }
  }
  
  Future<void> _savePoem() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final poemProvider = Provider.of<PoemGenerationProvider>(context, listen: false);
      final poem = poemProvider.currentPoem;
      
      if (poem == null) {
        throw Exception('No poem to save');
      }
      
      // Only update if content changed
      if (_poemController.text != poem.content || _titleController.text != poem.title) {
        final success = await poemProvider.editPoem(
          poemId: poem.id,
          newContent: _poemController.text,
          newTitle: _titleController.text,
        );
        
        if (!success) {
          throw Exception('Failed to save poem');
        }
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poem saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
    } catch (e) {
      AppLogger.e('Error saving poem', e);
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save poem';
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _sharePoem() async {
    if (_isSharing) return;
    
    setState(() {
      _isSharing = true;
      _errorMessage = null;
    });
    
    try {
      final poemProvider = Provider.of<PoemGenerationProvider>(context, listen: false);
      final poem = poemProvider.currentPoem;
      
      if (poem == null) {
        throw Exception('No poem to share');
      }
      
      // In a real app, we'd generate a shareable link or image here
      // For now, just share the text content
      final shareText = '${_titleController.text}\n\n${_poemController.text}\n\n- Created with PoemVision AI';
      
      await Share.share(shareText, subject: _titleController.text);
      
      setState(() {
        _isSharing = false;
      });
    } catch (e) {
      AppLogger.e('Error sharing poem', e);
      setState(() {
        _isSharing = false;
        _errorMessage = 'Failed to share poem';
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      
      // If canceling edit, revert to original
      if (!_isEditing) {
        final poemProvider = Provider.of<PoemGenerationProvider>(context, listen: false);
        final poem = poemProvider.currentPoem;
        
        if (poem != null) {
          _poemController.text = poem.content;
          _titleController.text = poem.title;
        }
      }
    });
  }
  
  Future<void> _copyToClipboard() async {
    try {
      final text = '${_titleController.text}\n\n${_poemController.text}';
      await Clipboard.setData(ClipboardData(text: text));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poem copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error copying to clipboard', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy poem'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  void _selectFrame(int index) {
    final isPremium = _frames[index].isPremium;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final isUserPremium = user != null && user['isPremium'] == true;
    
    if (isPremium && !isUserPremium) {
      // Show premium upgrade prompt
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Premium Frame'),
          content: const Text(
            'This frame is only available for premium users. Upgrade to access all premium frames.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to premium upgrade
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _selectedFrameIndex = index;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Poem'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy poem',
            onPressed: _copyToClipboard,
          ),
          // Share button
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share),
            tooltip: 'Share poem',
            onPressed: _isSharing ? null : _sharePoem,
          ),
        ],
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
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _savePoem,
              backgroundColor: AppTheme.primaryColor,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
            )
          : null,
    );
  }
  
  Widget _buildContent() {
    final poemProvider = Provider.of<PoemGenerationProvider>(context);
    final poem = poemProvider.currentPoem;
    
    if (poem == null) {
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
              'No poem found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try generating a new poem',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('${RoutePaths.poemCustomization}/${widget.analysisId}'),
              child: const Text('Create New Poem'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Frame selection
        Container(
          height: 80,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _frames.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final frame = _frames[index];
              final isSelected = index == _selectedFrameIndex;
              
              return GestureDetector(
                onTap: () => _selectFrame(index),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          frame.assetPath,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            frame.name,
                            style: const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                          if (frame.isPremium) ...[
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 10,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Poem display
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_frames[_selectedFrameIndex].assetPath),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  _isEditing
                      ? TextFormField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        )
                      : Text(
                          _titleController.text,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                  
                  const SizedBox(height: 16),
                  
                  // Poem text
                  _isEditing
                      ? TextFormField(
                          controller: _poemController,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(16),
                            hintText: 'Enter your poem text',
                          ),
                        )
                      : Text(
                          _poemController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom buttons
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleEditing,
                  icon: Icon(_isEditing ? Icons.close : Icons.edit),
                  label: Text(_isEditing ? 'Cancel' : 'Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go(RoutePaths.gallery),
                  icon: const Icon(Icons.collections),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Model for frame options
class _FrameOption {
  final String name;
  final String assetPath;
  final bool isPremium;
  
  const _FrameOption({
    required this.name,
    required this.assetPath,
    this.isPremium = false,
  });
}
