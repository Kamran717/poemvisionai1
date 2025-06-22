import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  User? _user;
  String? _errorMessage;

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

      final user = await _authService.refreshUserData();
      
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      // Navigate to login screen - would be handled by auth state in production
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to logout: $e';
      });
    }
  }

  Future<void> _upgradeToPremium() async {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    // Show upgrade options dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Upgrade to Premium',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock premium features:',
                style: TextStyle(color: sageGreen.withOpacity(0.9), fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem('✨ Unlimited poem generation'),
              _buildFeatureItem('🎨 Premium frames and templates'),
              _buildFeatureItem('💾 Save unlimited poems'),
              _buildFeatureItem('📤 Enhanced sharing options'),
              _buildFeatureItem('🚀 Priority processing'),
              _buildFeatureItem('📧 Premium customer support'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: blueGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: blueGray.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: yellow, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '\$9.99/month or \$79.99/year',
                        style: TextStyle(
                          color: yellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: sageGreen,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initiatePayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueGray,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(String feature) {
    const Color sageGreen = Color(0xFFC8C7B9);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        feature,
        style: TextStyle(
          color: sageGreen.withOpacity(0.9),
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (!mounted) return;
    
    // Navigate directly to the upgrade screen instead of showing a loading dialog
    // This avoids the NavigatorState issues with async operations
    context.pushNamed('upgrade');
  }

  Future<void> _manageSubscription() async {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Manage Subscription',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: yellow, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Premium Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Your premium membership includes:',
                style: TextStyle(color: sageGreen.withOpacity(0.9)),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('✅ Unlimited poem generation'),
              _buildFeatureItem('✅ Premium frames and templates'),
              _buildFeatureItem('✅ Unlimited saved poems'),
              _buildFeatureItem('✅ Enhanced sharing options'),
              const SizedBox(height: 16),
              if (_user?.membershipEnd != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: blueGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: blueGray.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: yellow, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Expires: ${_formatDate(_user!.membershipEnd!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: sageGreen,
              ),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _renewSubscription();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueGray,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Renew'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renewSubscription() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription management would integrate with your payment provider'),
        backgroundColor: Color(0xFF7DA1BF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);

    return Scaffold(
      backgroundColor: primaryBlack,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: blueGray),
            onPressed: () {
              // Navigate to settings screen
              // This will be implemented when we connect this to the router
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: yellow))
          : _errorMessage != null
              ? _buildErrorView()
              : _user == null
                  ? _buildNotLoggedInView()
                  : _buildProfileView(),
    );
  }

  Widget _buildErrorView() {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: blueGray,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 80,
                color: sageGreen.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              const Text(
                'Not Logged In',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please login to view your profile',
                style: TextStyle(
                  color: sageGreen.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.goNamed('login');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: blueGray,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: blueGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: blueGray.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: yellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Want Premium Features?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to access premium frames, save poems, and more!',
                      style: TextStyle(
                        fontSize: 14,
                        color: sageGreen.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.goNamed('login'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: yellow),
                          foregroundColor: yellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Login for Premium'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    if (_user == null) return const SizedBox.shrink();
    
    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF7DA1BF),
                    child: Text(
                      _getInitials(_user!.username),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username
                  Text(
                    _user!.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Email
                  Text(
                    _user!.email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFC8C7B9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Membership info
            _buildMembershipCard(),
            const SizedBox(height: 24),
            
            // Account section
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Account options
            _buildOptionTile(
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {
                // Navigate to edit profile screen
              },
            ),
            _buildOptionTile(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                // Navigate to change password screen
              },
            ),
            
            const SizedBox(height: 24),
            
            // App section
            const Text(
              'App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // App options
            _buildOptionTile(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                // Navigate to help screen
              },
            ),
            _buildOptionTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                // Navigate to privacy policy screen
              },
            ),
            _buildOptionTile(
              icon: Icons.description,
              title: 'Terms of Service',
              onTap: () {
                // Navigate to terms screen
              },
            ),
            
            const SizedBox(height: 32),
            
            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.red.shade300),
                  foregroundColor: Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard() {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);
    
    final isPremium = _user?.isPremium ?? false;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isPremium ? blueGray.withOpacity(0.8) : sageGreen.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.star_border,
                  color: yellow,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  isPremium ? 'Premium Membership' : 'Free Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.white : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isPremium
                  ? 'You have access to all premium features'
                  : 'Upgrade to access premium features',
              style: TextStyle(
                fontSize: 14,
                color: isPremium ? Colors.white.withOpacity(0.9) : sageGreen.withOpacity(0.9),
              ),
            ),
            if (isPremium && _user?.membershipEnd != null) ...[
              const SizedBox(height: 8),
              Text(
                'Expires on: ${_formatDate(_user!.membershipEnd!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPremium ? _manageSubscription : _upgradeToPremium,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium ? yellow : blueGray,
                  foregroundColor: isPremium ? Colors.black87 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isPremium ? 'Manage Subscription' : 'Upgrade Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // Theme colors
    const Color blueGray = Color(0xFF7DA1BF);
    const Color sageGreen = Color(0xFFC8C7B9);
    
    return ListTile(
      leading: Icon(icon, color: blueGray),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: Icon(Icons.chevron_right, color: sageGreen),
      onTap: onTap,
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
