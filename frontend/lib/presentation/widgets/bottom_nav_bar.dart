import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

/// Bottom navigation bar for the app
class BottomNavBar extends StatelessWidget {
  /// Current index of the selected tab
  final int currentIndex;
  
  /// Callback when a tab is tapped
  final Function(int) onTap;
  
  /// Constructor
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textLightColor,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_photo_alternate),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.collections),
          label: 'Gallery',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
