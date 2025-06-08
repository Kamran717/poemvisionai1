import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'system';
  bool _notificationsEnabled = true;
  bool _saveImageWithPoems = true;
  bool _autoSaveCreations = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    _selectedTheme = await profileProvider.getThemePreference();
    _notificationsEnabled = await profileProvider.getNotificationPreference();
    
    // These would normally be loaded from user preferences
    // For now, we'll use defaults
    _saveImageWithPoems = true;
    _autoSaveCreations = true;
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      
      final success = await profileProvider.updatePreferences(
        themePreference: _selectedTheme,
        notificationPreference: _notificationsEnabled,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save settings';
        });
      }
    } catch (e) {
      AppLogger.e('Error saving settings', e);
      setState(() {
        _errorMessage = 'An error occurred while saving settings';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          // App Theme
          const Text(
            'Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('System Theme'),
                  subtitle: const Text('Match your device settings'),
                  value: 'system',
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('Light Theme'),
                  subtitle: const Text('Light colors and elements'),
                  value: 'light',
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Dark colors and elements'),
                  value: 'dark',
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Notifications
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive updates and important information'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Creation Settings
          const Text(
            'Creation Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Save Image with Poems'),
                  subtitle: const Text('Store the original image with each poem'),
                  value: _saveImageWithPoems,
                  onChanged: (value) {
                    setState(() {
                      _saveImageWithPoems = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Auto-Save Creations'),
                  subtitle: const Text('Automatically save all generated poems'),
                  value: _autoSaveCreations,
                  onChanged: (value) {
                    setState(() {
                      _autoSaveCreations = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Default Poem Settings
          const Text(
            'Default Poem Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Default Poem Type'),
                  subtitle: const Text('Free Verse'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // This would open a selection dialog in a real app
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This feature will be implemented in a future update'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Default Frame Style'),
                  subtitle: const Text('Classic'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // This would open a selection dialog in a real app
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This feature will be implemented in a future update'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data & Privacy
          const Text(
            'Data & Privacy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Clear App Data'),
                  subtitle: const Text('Remove all cached data'),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear App Data'),
                        content: const Text('Are you sure you want to clear all cached data? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('App data cleared'),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Clear Data'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Export User Data'),
                  subtitle: const Text('Download all your personal data'),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This feature will be implemented in a future update'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Privacy Settings'),
                  subtitle: const Text('Manage how your data is used'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This feature will be implemented in a future update'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
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
                      'Save Settings',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
