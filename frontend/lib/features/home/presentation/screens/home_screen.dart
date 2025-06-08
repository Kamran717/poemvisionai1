import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';

/// Home screen of the application
class HomeScreen extends StatefulWidget {
  /// Constructor
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoemVision AI'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              const Text(
                'Welcome to PoemVision AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Transform your images into beautiful poems',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLightColor,
                ),
              ),
              const SizedBox(height: 24),
              
              // Create new poem card
              _buildActionCard(
                title: 'Create New Poem',
                description: 'Upload an image and generate a custom poem',
                icon: Icons.add_photo_alternate,
                color: AppTheme.primaryColor,
                onTap: () => context.go(RoutePaths.imageUpload),
              ),
              const SizedBox(height: 16),
              
              // View gallery card
              _buildActionCard(
                title: 'View Your Gallery',
                description: 'Browse your saved poems and creations',
                icon: Icons.collections,
                color: AppTheme.secondaryColor,
                onTap: () => context.go(RoutePaths.gallery),
              ),
              const SizedBox(height: 16),
              
              // Membership card
              _buildActionCard(
                title: 'Upgrade Membership',
                description: 'Get premium features and unlimited generations',
                icon: Icons.star,
                color: AppTheme.accentColor,
                onTap: () => context.go(RoutePaths.membership),
              ),
              const SizedBox(height: 24),
              
              // Recent creations section
              const Text(
                'Recent Creations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Empty state or sample creations
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No creations yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload an image to get started',
                      style: TextStyle(
                        color: AppTheme.textLightColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go(RoutePaths.imageUpload),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Create New Poem'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Home index
        onTap: (index) {
          if (index != 0) {
            switch (index) {
              case 1:
                context.go(RoutePaths.imageUpload);
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
  
  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textLightColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
