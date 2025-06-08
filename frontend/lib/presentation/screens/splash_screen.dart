import 'package:flutter/material.dart';
import 'package:animated_introduction/animated_introduction.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/routes/app_router.dart';
import 'package:frontend/core/utils/app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    // Start the animation as soon as the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
    
    // Navigate to intro screen after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        navigateToIntro();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void navigateToIntro() {
    AppLogger.d('Navigating to intro screen');
    AppRouter.navigateWithFade(context, RoutePaths.intro);
  }
  
  @override
  Widget build(BuildContext context) {
    // Define pages for the animated introduction
    final pages = [
      AnimatedIntroductionPage(
        title: 'PoemVision AI',
        description: 'Transform your images into beautiful poems',
        backgroundColor: AppTheme.primaryColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        descriptionTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
        decorationImage: const AnimatedIntroductionDecorationImage(
          alignment: Alignment.center,
          image: AssetImage('assets/images/logo.png'),
          height: 200,
          width: 200,
        ),
        decoration: [
          AnimatedIntroductionDecoration(
            alignment: Alignment.topRight,
            child: AnimatedIntroductionLiquidCircle(
              color: Colors.white.withOpacity(0.2),
              delay: const Duration(milliseconds: 500),
              duration: const Duration(seconds: 2),
              size: 100,
            ),
          ),
          AnimatedIntroductionDecoration(
            alignment: Alignment.bottomLeft,
            child: AnimatedIntroductionLiquidCircle(
              color: Colors.white.withOpacity(0.2),
              delay: const Duration(milliseconds: 750),
              duration: const Duration(seconds: 2),
              size: 150,
            ),
          ),
        ],
      ),
    ];
    
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: AnimatedIntroduction(
        pages: pages,
        animateSkipButton: false,
        hideBottomBar: true,
        autoStartAnimation: true,
        animateScrollIndicator: false,
        onTapSkipButton: navigateToIntro,
        onTapDoneButton: navigateToIntro,
        automaticallyImplySkipAndDoneButtons: false,
      ),
    );
  }
}
