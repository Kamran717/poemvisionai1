import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Add a small delay for splash effect
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntroduction = prefs.getBool('seen_introduction') ?? false;
    
    if (mounted) {
      if (!hasSeenIntroduction) {
        // User hasn't seen introduction yet
        context.go('/onboarding');
        return;
      }
      
      // Check authentication state
      final authService = Provider.of<AuthService>(context, listen: false);
      final isLoggedIn = await authService.initialize();
      
      if (isLoggedIn) {
        // User is logged in, go to home
        context.go('/home');
      } else {
        // User is not logged in, go to login screen
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Scaffold(
      backgroundColor: primaryBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: blueGray.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: blueGray, width: 2),
              ), 
              child: Image.asset(
                "assets/images/brand_hero.png", 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: blueGray,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PoemVision AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Transform images into beautiful poems',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: sageGreen.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(yellow),
            ),
          ],
        ),
      ),
    );
  }
}
