import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  void _loadProfile() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;
    
    if (profile != null && profile.displayName != null) {
      _nameController.text = profile.displayName!;
    } else if (profile != null) {
      // Use email prefix as default name if no display name is set
      _nameController.text = profile.email.split('@').first;
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProvider.updateProfile(
        displayName: _nameController.text.trim(),
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = profileProvider.errorMessage ?? 'Failed to update profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error updating profile', e);
      setState(() {
        _errorMessage = 'An error occurred while updating profile';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectProfilePhoto() async {
    // In a real app, we would implement image picking and uploading here
    // For now, we'll just show a dialog
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Profile Photo'),
        content: const Text('This feature will be implemented in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          final profile = profileProvider.profile;
          
          if (profile == null) {
            return const Center(
              child: Text('Profile not loaded'),
            );
          }
          
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile photo
                  GestureDetector(
                    onTap: _selectProfilePhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor,
                          backgroundImage: profile.photoUrl != null
                              ? NetworkImage(profile.photoUrl!)
                              : null,
                          child: profile.photoUrl == null
                              ? Text(
                                  profile.initials,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Email (read-only)
                  TextFormField(
                    initialValue: profile.email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Display name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a display name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Password change option
                  ListTile(
                    title: const Text('Change Password'),
                    leading: const Icon(Icons.lock),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to change password screen
                      // This would be implemented in a future update
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Change Password'),
                          content: const Text('This feature will be implemented in a future update.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const Divider(),
                  
                  // Email verification status
                  ListTile(
                    title: const Text('Email Verification'),
                    subtitle: Text(
                      profile.emailVerified
                          ? 'Your email is verified'
                          : 'Your email is not verified',
                    ),
                    leading: const Icon(Icons.verified_user),
                    trailing: profile.emailVerified
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          )
                        : TextButton(
                            onPressed: () async {
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
                            child: const Text('Verify'),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
