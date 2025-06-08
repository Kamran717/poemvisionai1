import 'package:flutter/material.dart';
import 'package:animated_introduction/animated_introduction.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/service_locator.dart';
import 'package:frontend/core/storage/local_storage.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final LocalStorage _localStorage = serviceLocator.get<LocalStorage>();
  
  @override
  void initState() {
    super.initState();
    // Set intro as shown when this screen is displayed
    _markIntroAsShown();
  }
  
  Future<void> _markIntroAsShown() async {
    await _localStorage.setBool('intro_shown', true);
  }
  
  void _navigateToHome() {
    AppLogger.d('Navigating to home screen');
    context.go(RoutePaths.home);
  }
  
  @override
  Widget build(BuildContext context) {
    // Define pages for the animated introduction
    final pages = [
      // First intro page
      AnimatedIntroductionPage(
        title: 'Image to Poem',
        description: 'Upload any image and let AI transform it into a beautiful poem',
        backgroundColor: AppTheme.primaryColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        descriptionTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: [
          AnimatedIntroductionDecoration(
            alignment: Alignment.center,
            child: AnimatedIntroductionImage(
              image: const AssetImage('assets/images/intro_image_upload.png'),
              width: 250,
              height: 250,
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
      
      // Second intro page
      AnimatedIntroductionPage(
        title: 'Customize Your Poem',
        description: 'Choose from different poem styles, lengths, and themes to match your vision',
        backgroundColor: Colors.indigo,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        descriptionTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: [
          AnimatedIntroductionDecoration(
            alignment: Alignment.center,
            child: AnimatedIntroductionImage(
              image: const AssetImage('assets/images/intro_customize.png'),
              width: 250,
              height: 250,
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
      
      // Third intro page
      AnimatedIntroductionPage(
        title: 'Share Your Creations',
        description: 'Share your beautiful poem-images with friends and family, or save them to your gallery',
        backgroundColor: Colors.deepPurple,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        descriptionTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: [
          AnimatedIntroductionDecoration(
            alignment: Alignment.center,
            child: AnimatedIntroductionImage(
              image: const AssetImage('assets/images/intro_share.png'),
              width: 250,
              height: 250,
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    ];
    
    return Scaffold(
      body: AnimatedIntroduction(
        pages: pages,
        animateSkipButton: true,
        skipButtonText: 'Skip',
        skipButtonTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        doneButtonText: 'Get Started',
        doneButtonTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        indicatorType: IndicatorType.circle,
        indicatorColor: Colors.white,
        onTapSkipButton: _navigateToHome,
        onTapDoneButton: _navigateToHome,
        scrollIndicatorEffect: WormEffect(),
      ),
    );
  }
}
