import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Welcome to PoemVision AI",
      description: "Transform your precious memories into beautiful, personalized poems using the power of artificial intelligence.",
      imagePath: "assets/images/brand_hero.png",
      color: const Color(0xFFEDD050), // Yellow
    ),
    OnboardingPageData(
      title: "Capture & Create",
      description: "Simply upload any image from your gallery or take a new photo, and watch as AI analyzes it to craft a unique poem.",
      imagePath: "assets/images/onboarding_1.png",
      color: const Color(0xFF7DA1BF), // Blue Gray
    ),
    OnboardingPageData(
      title: "Beautiful Frames",
      description: "Choose from our collection of elegant frames to make your poem visually stunning and ready to share.",
      imagePath: "assets/images/onboarding_2.jpg",
      color: const Color(0xFFC8C7B9), // Sage Green
    ),
    OnboardingPageData(
      title: "Save & Share",
      description: "Keep your favorite poems in your personal gallery and share them with friends and family on social media.",
      imagePath: "assets/images/onboarding_3.jpg",
      color: const Color(0xFF7DA1BF), // Blue Gray
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Scaffold(
      backgroundColor: primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _onIntroEnd,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        color: sageGreen.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => _buildDot(index),
                ),
              ),
            ),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _currentPage == _totalPages - 1 ? _onIntroEnd : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueGray,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData) {
    const Color sageGreen = Color(0xFFC8C7B9);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image instead of icon
          Container(
            width: 280,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pageData.color.withOpacity(0.3), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                pageData.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderForImage(pageData);
                },
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            pageData.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            pageData.description,
            style: TextStyle(
              fontSize: 16,
              color: sageGreen.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    const Color blueGray = Color(0xFF7DA1BF);
    const Color sageGreen = Color(0xFFC8C7B9);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      width: _currentPage == index ? 24.0 : 10.0,
      height: 10.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? blueGray : sageGreen.withOpacity(0.4),
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
  }

  Widget _buildPlaceholderForImage(OnboardingPageData pageData) {
    IconData iconData;
    switch (pageData.imagePath) {
      case "assets/images/brand_hero.png":
        iconData = Icons.auto_awesome;
        break;
      case "assets/images/onboarding_1.png":
        iconData = Icons.photo_camera;
        break;
      case "assets/images/onboarding_2.jpg":
        iconData = Icons.collections;
        break;
      case "assets/images/onboarding_3.jpg":
        iconData = Icons.share;
        break;
      default:
        iconData = Icons.image;
    }

    return Container(
      width: 280,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pageData.color.withOpacity(0.8),
            pageData.color.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Image placeholder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onIntroEnd() async {
    // Mark that the user has seen the introduction
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_introduction', true);
    
    // Navigate to home screen to allow free access without login
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;
  final Color color;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.color,
  });
}
