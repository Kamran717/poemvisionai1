import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/presentation/common/app_header.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/services/service_locator.dart';
import 'package:frontend/core/storage/secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = serviceLocator.get<ApiClient>();
  final SecureStorage _secureStorage = serviceLocator.get<SecureStorage>();
  
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      AppLogger.d('Loading user profile');
      
      // TODO: Implement actual API call
      // This is a placeholder until we implement the actual API call
      // In a real implementation, we would call:
      // final response = await _apiClient.getUserProfile();
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock user data
      final mockUserData = {
        'id': 1,
        'username': 'poemuser',
        'email': 'user@example.com',
        'isPremium': false,
        'creationCount': 12,
        'memberSince': '2025-01-15T10:30:00.000Z',
        'stats': {
          'poemTypes': {
            'love': 4,
            'inspirational': 3,
            'haiku': 2,
            'sonnet': 1,
            'other': 2,
          },
          'timeSaved': {
            'hours': 5,
            'minutes': 45,
          },
        },
      };
      
      setState(() {
        _isLoading = false;
        _userData = mockUserData;
      });
    } catch (e) {
      AppLogger.e('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile. Please try again.';
      });
    }
  }
  
  Future<void> _logout() async {
    try {
      AppLogger.d('Logging out user');
      
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );
      
      if (shouldLogout == true) {
        // Clear auth token and user data
        await _secureStorage.clearAuthData();
        
        // Navigate to login screen
        if (mounted) {
          context.go(RoutePaths.login);
        }
      }
    } catch (e) {
      AppLogger.e('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log out. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  void _navigateToMembershipUpgrade() {
    AppLogger.d('Navigating to membership upgrade');
    // TODO: Implement navigation to membership upgrade
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upgrade functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _navigateToSettings() {
    AppLogger.d('Navigating to settings');
    // TODO: Implement navigation to settings
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            switch (index) {
              case 0:
                context.go(RoutePaths.home);
                break;
              case 1:
                context.go(RoutePaths.imageUpload);
                break;
              case 2:
                context.go(RoutePaths.gallery);
                break;
            }
          }
        },
      ),
    );
  }
  
  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_userData == null) {
      return const Center(
        child: Text('No user data available'),
      );
    }
    
    // Extract user data
    final username = _userData!['username'] as String;
    final email = _userData!['email'] as String;
    final isPremium = _userData!['isPremium'] as bool;
    final creationCount = _userData!['creationCount'] as int;
    final memberSince = DateTime.parse(_userData!['memberSince'] as String);
    
    // Format member since date
    final formattedDate = '${memberSince.day}/${memberSince.month}/${memberSince.year}';
    
    // Extract stats
    final poemTypes = (_userData!['stats']['poemTypes'] as Map<String, dynamic>)
        .entries
        .toList()
        .where((entry) => entry.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    final timeSavedHours = _userData!['stats']['timeSaved']['hours'] as int;
    final timeSavedMinutes = _userData!['stats']['timeSaved']['minutes'] as int;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Member since $formattedDate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Membership status
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
                      Icon(
                        isPremium ? Icons.star : Icons.star_border,
                        color: isPremium ? Colors.amber : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPremium ? 'Premium Member' : 'Free Plan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isPremium)
                    const Text(
                      'You have access to all premium features!',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upgrade to Premium for:',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureItem('Access to all poem types and styles'),
                        _buildFeatureItem('Longer poems with more customization'),
                        _buildFeatureItem('Premium frames and styling options'),
                        _buildFeatureItem('Ad-free experience'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _navigateToMembershipUpgrade,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Upgrade to Premium'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats section
          const Text(
            'Your Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Poems Created',
                  value: creationCount.toString(),
                  icon: Icons.auto_awesome,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Time Saved',
                  value: '$timeSavedHours h $timeSavedMinutes m',
                  icon: Icons.timer,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Favorite poem types
          if (poemTypes.isNotEmpty) ...[
            const Text(
              'Favorite Poem Types',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ...poemTypes.take(3).map((entry) => _buildPoemTypeItem(
              type: entry.key,
              count: entry.value as int,
            )),
          ],
          
          const SizedBox(height: 24),
          
          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPoemTypeItem({
    required String type,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPoemTypeIcon(type),
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type.capitalize(),
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getPoemTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'love':
        return Icons.favorite;
      case 'inspirational':
        return Icons.lightbulb;
      case 'haiku':
        return Icons.format_align_center;
      case 'sonnet':
        return Icons.format_quote;
      case 'memorial':
        return Icons.memory;
      case 'religious-general':
      case 'spiritual':
        return Icons.cloud;
      default:
        return Icons.auto_stories;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
