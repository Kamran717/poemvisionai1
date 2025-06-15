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
      icon: Icons.auto_awesome,
      color: const Color(0xFFEDD050), // Yellow
    ),
    OnboardingPageData(
      title: "Capture & Create",
      description: "Simply upload any image from your gallery or take a new photo, and watch as AI analyzes it to craft a unique poem.",
      icon: Icons.camera_alt,
      color: const Color(0xFF7DA1BF), // Blue Gray
    ),
    OnboardingPageData(
      title: "Beautiful Frames",
      description: "Choose from our collection of elegant frames to make your poem visually stunning and ready to share.",
      icon: Icons.crop_landscape,
      color: const Color(0xFFC8C7B9), // Sage Green
    ),
    OnboardingPageData(
      title: "Save & Share",
      description: "Keep your favorite poems in your personal gallery and share them with friends and family on social media.",
      icon: Icons.share,
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
          // Icon
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: pageData.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: pageData.color.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              pageData.icon,
              size: 80,
              color: pageData.color,
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
  final IconData icon;
  final Color color;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
