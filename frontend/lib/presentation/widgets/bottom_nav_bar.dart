import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

/// Bottom navigation bar widget
class BottomNavBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;
  
  /// Callback when a tab is tapped
  final Function(int) onTap;
  
  /// Whether to show labels
  final bool showLabels;
  
  /// Constructor
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: showLabels,
      showUnselectedLabels: showLabels,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_photo_alternate_outlined),
          activeIcon: Icon(Icons.add_photo_alternate),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.collections_outlined),
          activeIcon: Icon(Icons.collections),
          label: 'Gallery',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
