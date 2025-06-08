import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/features/profile/domain/models/user_profile.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/presentation/widgets/bottom_nav_bar.dart';
import 'package:frontend/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:frontend/features/profile/presentation/screens/membership_screen.dart';
import 'package:frontend/features/profile/presentation/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.loadProfile();
      await profileProvider.loadUsageStats();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading profile', e);
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
    
    if (result == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      if (mounted) {
        context.go(RoutePaths.login);
      }
    }
  }
  
  Future<void> _showDeleteAccountDialog() async {
    final TextEditingController passwordController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is permanent and cannot be undone. All your data, including poems and saved creations will be deleted.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text('Please enter your password to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
    
    if (result == true && mounted) {
      if (passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProvider.deleteAccount(
        password: passwordController.text,
      );
      
      if (success && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        
        if (mounted) {
          context.go(RoutePaths.login);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please check your password and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    passwordController.dispose();
  }
  
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }
  
  void _navigateToMembership() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MembershipScreen(),
      ),
    );
  }
  
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
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
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3, // Profile index
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
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profile = profileProvider.profile;
        
        if (profile == null) {
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
                  'Failed to load profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profileProvider.errorMessage ?? 'Please try again',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                _buildProfileHeader(profile, profileProvider),
                
                const SizedBox(height: 24),
                
                // Membership card
                _buildMembershipCard(profileProvider),
                
                const SizedBox(height: 24),
                
                // Usage statistics
                if (profileProvider.usageStats != null)
                  _buildUsageStats(profileProvider.usageStats!),
                
                const SizedBox(height: 24),
                
                // Menu options
                _buildMenuOptions(),
                
                const SizedBox(height: 40),
                
                // Footer actions
                Center(
                  child: TextButton(
                    onPressed: _showDeleteAccountDialog,
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProfileHeader(UserProfile profile, ProfileProvider profileProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar
            if (profile.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.network(
                  profile.photoUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAvatarFallback(profile);
                  },
                ),
              )
            else
              _buildAvatarFallback(profile),
            
            const SizedBox(width: 16),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        profile.emailVerified
                            ? Icons.verified_user
                            : Icons.warning,
                        size: 16,
                        color: profile.emailVerified
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profile.emailVerified
                            ? 'Verified'
                            : 'Unverified',
                        style: TextStyle(
                          fontSize: 12,
                          color: profile.emailVerified
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      if (!profile.emailVerified) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final success = await profileProvider.sendVerificationEmail();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Verification email sent'
                                        : 'Failed to send verification email',
                                  ),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditProfile,
              tooltip: 'Edit profile',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatarFallback(UserProfile profile) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        profile.initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildMembershipCard(ProfileProvider profileProvider) {
    final isActive = profileProvider.hasPremium;
    final currentPlan = profileProvider.currentPlan;
    
    return GestureDetector(
      onTap: _navigateToMembership,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isActive ? AppTheme.primaryColor : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    profileProvider.membershipStatusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.black,
                    ),
                  ),
                  Icon(
                    Icons.star,
                    color: isActive ? Colors.amber : Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (currentPlan != null && currentPlan.isFree) ...[
                Text(
                  'Upgrade to unlock premium features:',
                  style: TextStyle(
                    color: isActive ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFeatureItem('All poem types', isActive),
                    _buildFeatureItem('Unlimited creations', isActive),
                    _buildFeatureItem('Premium frames', isActive),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToMembership,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: isActive ? AppTheme.primaryColor : Colors.white,
                      backgroundColor: isActive ? Colors.white : AppTheme.primaryColor,
                    ),
                    child: const Text('Upgrade Now'),
                  ),
                ),
              ] else if (currentPlan != null) ...[
                Text(
                  profileProvider.profile?.membershipExpiresAt != null
                      ? 'Renews on ${_formatDate(profileProvider.profile!.membershipExpiresAt!)}'
                      : 'Lifetime subscription',
                  style: TextStyle(
                    color: isActive ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                if (isActive) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _navigateToMembership,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Manage Subscription'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToMembership,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('Renew Subscription'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String text, bool isActive) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: isActive ? Colors.white : AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUsageStats(Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  stats['poems_generated'] as int? ?? 0,
                  'Poems',
                  Icons.auto_stories,
                ),
                _buildStatItem(
                  stats['images_analyzed'] as int? ?? 0,
                  'Images',
                  Icons.image,
                ),
                _buildStatItem(
                  stats['creations_shared'] as int? ?? 0,
                  'Shared',
                  Icons.share,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Creations this month'),
                Text(
                  '${stats['creations_this_month'] as int? ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (stats['creation_limit_reached'] == true ||
                (stats['daily_limit'] != null && stats['daily_used'] != null)) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily usage'),
                  Text(
                    '${stats['daily_used'] as int? ?? 0} / ${stats['daily_limit'] as int? ?? 5}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: stats['creation_limit_reached'] == true
                          ? Colors.red
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (stats['creation_limit_reached'] == true) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Daily creation limit reached. Upgrade to Premium for unlimited creations.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(int value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMenuOptions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToEditProfile,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Membership'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToMembership,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToSettings,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to help and support
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show about dialog
            },
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 30) {
      return '${difference + 1} days';
    } else {
      return '${(difference / 30).round()} months';
    }
  }
}
