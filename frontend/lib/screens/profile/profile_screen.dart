import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
              // This will be implemented when we connect this to the router
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _user == null
                  ? _buildNotLoggedInView()
                  : _buildProfileView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserProfile,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'Not Logged In',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please login to view your profile',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen
              // This will be implemented when we connect this to the router
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
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
                    backgroundColor: Colors.blue.shade200,
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
                    ),
                  ),
                  
                  // Email
                  Text(
                    _user!.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
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
    final isPremium = _user?.isPremium ?? false;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isPremium ? Colors.blue.shade800 : Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.star_border,
                  color: isPremium ? Colors.amber : Colors.grey.shade700,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  isPremium ? 'Premium Membership' : 'Free Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.white : Colors.grey.shade800,
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
                color: isPremium ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
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
                onPressed: () {
                  // Navigate to membership screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium ? Colors.white : Colors.blue,
                  foregroundColor: isPremium ? Colors.blue.shade800 : Colors.white,
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
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
