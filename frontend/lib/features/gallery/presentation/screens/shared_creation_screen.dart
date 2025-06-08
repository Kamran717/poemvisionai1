import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/features/gallery/domain/models/creation.dart';
import 'package:frontend/features/gallery/presentation/providers/gallery_provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';

class SharedCreationScreen extends StatefulWidget {
  final String shareCode;

  const SharedCreationScreen({
    super.key,
    required this.shareCode,
  });

  @override
  State<SharedCreationScreen> createState() => _SharedCreationScreenState();
}

class _SharedCreationScreenState extends State<SharedCreationScreen> {
  bool _isLoading = true;
  Creation? _creation;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadSharedCreation();
  }
  
  Future<void> _loadSharedCreation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // In a real app, we'd fetch the creation using the share code
      // For now, create a mock creation
      await Future.delayed(const Duration(seconds: 1));
      
      final mockCreation = Creation(
        id: 'shared_creation',
        poem: _createMockPoem(),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        frameType: 'elegant',
        isPublic: true,
        shareUrl: 'https://poemvision.ai/share/${widget.shareCode}',
      );
      
      setState(() {
        _creation = mockCreation;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading shared creation', e);
      setState(() {
        _errorMessage = 'Failed to load shared creation';
        _isLoading = false;
      });
    }
  }
  
  // Helper method to create a mock poem for demonstration
  dynamic _createMockPoem() {
    return {
      'id': 'shared_poem',
      'title': 'Shared Sunset Beauty',
      'content': 'The sun sets low across the bay,\n'
          'Painting skies in shades of gold.\n'
          'Another beautiful closing day,\n'
          'A sight that never grows old.\n\n'
          'Waves lap gently on the shore,\n'
          'As darkness slowly falls.\n'
          'Nature\'s peace I do adore,\n'
          'This moment enthralls.\n\n'
          'Tomorrow brings a brand new dawn,\n'
          'But tonight, this view I treasure.\n'
          'The day\'s light nearly gone,\n'
          'This sunset brings such pleasure.',
      'poem_type': 'general_verse',
      'analysis_id': 'shared_analysis',
      'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    };
  }
  
  Future<void> _shareCreation() async {
    if (_creation == null) return;
    
    try {
      // In a real app, we'd use the share_plus package to share the URL
      final shareText = '${_creation!.poem.title}\n\n${_creation!.poem.content}\n\n'
          'Check out this poem I found on PoemVision AI: ${_creation!.shareUrl}';
      
      await Share.share(shareText, subject: _creation!.poem.title);
    } catch (e) {
      AppLogger.e('Error sharing creation', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share creation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _copyToClipboard() async {
    if (_creation == null) return;
    
    try {
      final text = '${_creation!.poem.title}\n\n${_creation!.poem.content}';
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
  
  void _createInspiredPoem() {
    if (_creation == null) return;
    
    // Navigate to poem creation screen
    context.go(RoutePaths.imageUpload);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Creation'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy poem',
            onPressed: _creation != null ? _copyToClipboard : null,
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share poem',
            onPressed: _creation != null ? _shareCreation : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      bottomNavigationBar: Container(
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
                onPressed: () => context.go(RoutePaths.home),
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _createInspiredPoem,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Create My Own'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_errorMessage != null) {
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
              'Creation Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'The shared creation could not be found or has been removed',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      );
    }
    
    if (_creation == null) {
      return const Center(
        child: Text('No creation data available'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creation card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage('assets/frames/${_creation!.frameType}.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.05),
                    BlendMode.darken,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    _creation!.poem.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Poem text
                  Text(
                    _creation!.poem.content,
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
          
          const SizedBox(height: 24),
          
          // Information about the creation
          const Text(
            'About this creation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_stories),
            title: const Text('Poem Type'),
            subtitle: Text(_creation!.poem.poemType.split('_').map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ')),
          ),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Created'),
            subtitle: Text(_formatDate(_creation!.createdAt)),
          ),
          
          const SizedBox(height: 16),
          
          // CTA for app download
          Card(
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Create Your Own Poems',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PoemVision AI turns your images into beautiful poems. Download the app and start creating!',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Link to app store
                        },
                        child: const Text('Download App'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.go(RoutePaths.home),
                        child: const Text('Try Web Version'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
