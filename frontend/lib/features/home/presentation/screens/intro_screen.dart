import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/theme/app_theme.dart';

/// Introduction screen shown after splash
class IntroScreen extends StatefulWidget {
  /// Constructor
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<IntroPage> _pages = [
    IntroPage(
      title: 'Welcome to PoemVision AI',
      description: 'Transform your images into beautiful poems with the power of AI',
      image: Icons.auto_awesome,
      color: AppTheme.primaryColor,
    ),
    IntroPage(
      title: 'Upload Your Images',
      description: 'Select or capture images that inspire you',
      image: Icons.image,
      color: AppTheme.secondaryColor,
    ),
    IntroPage(
      title: 'Generate Custom Poems',
      description: 'Our AI analyzes your images and creates personalized poems',
      image: Icons.text_fields,
      color: AppTheme.accentColor,
    ),
    IntroPage(
      title: 'Share Your Creations',
      description: 'Save, customize, and share your poems with friends and family',
      image: Icons.share,
      color: AppTheme.successColor,
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }
  
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }
  
  void _goToLogin() {
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text('Skip'),
                ),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildIntroPage(page);
                },
              ),
            ),
            
            // Indicators and button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index == _currentPage),
                    ),
                  ),
                  
                  // Next button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      backgroundColor: _pages[_currentPage].color,
                    ),
                    child: Icon(
                      _currentPage < _pages.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIntroPage(IntroPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.image,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          
          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textLightColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 16 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? _pages[_currentPage].color : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Data class for intro page content
class IntroPage {
  /// Title of the intro page
  final String title;
  
  /// Description text
  final String description;
  
  /// Icon to display
  final IconData image;
  
  /// Theme color
  final Color color;
  
  /// Constructor
  IntroPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
