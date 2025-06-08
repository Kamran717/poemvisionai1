import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';
import 'package:frontend/presentation/common/app_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Navigate based on selected index
    switch (index) {
      case 0:
        // Home - Already here
        break;
      case 1:
        // Image Upload
        context.go(RoutePaths.imageUpload);
        break;
      case 2:
        // Gallery
        context.go(RoutePaths.gallery);
        break;
      case 3:
        // Profile
        context.go(RoutePaths.profile);
        break;
    }
  }
  
  void _navigateToImageUpload() {
    AppLogger.d('Navigating to image upload screen');
    context.go(RoutePaths.imageUpload);
  }
  
  void _navigateToGallery() {
    AppLogger.d('Navigating to gallery screen');
    context.go(RoutePaths.gallery);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('PoemVision AI'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Will implement settings later
              AppLogger.d('Settings pressed');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              const AppHeader(
                title: 'Welcome to PoemVision AI',
                subtitle: 'Transform your images into beautiful poems',
              ),
              
              const SizedBox(height: 32),
              
              // Primary action card
              _buildActionCard(
                title: 'Create a New Poem',
                description: 'Upload an image and transform it into a poem',
                icon: Icons.add_photo_alternate_outlined,
                color: AppTheme.primaryColor,
                onTap: _navigateToImageUpload,
              ),
              
              const SizedBox(height: 24),
              
              // Secondary action card
              _buildActionCard(
                title: 'View Your Gallery',
                description: 'Browse your saved poems and creations',
                icon: Icons.photo_library_outlined,
                color: Colors.teal,
                onTap: _navigateToGallery,
              ),
              
              const SizedBox(height: 32),
              
              // Feature showcase
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Feature list
              _buildFeatureItem(
                icon: Icons.auto_awesome,
                title: 'AI-Powered Poems',
                description: 'Advanced AI analyzes your images and creates personalized poems',
              ),
              
              _buildFeatureItem(
                icon: Icons.style,
                title: 'Multiple Poem Styles',
                description: 'Choose from various poem types, lengths, and themes',
              ),
              
              _buildFeatureItem(
                icon: Icons.share,
                title: 'Easy Sharing',
                description: 'Share your creations directly to social media or via link',
              ),
              
              _buildFeatureItem(
                icon: Icons.palette,
                title: 'Beautiful Frames',
                description: 'Customize the look of your final poem with different frames',
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
  
  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
