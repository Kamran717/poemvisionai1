import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/creation/create_poem_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/onboarding/introduction_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/upgrade/upgrade_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    routes: [
      // Splash screen route
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(
          onNavigateToRegister: () => context.pushNamed('register'),
          onLoginSuccess: () => context.goNamed('home'),
          onNavigateToForgotPassword: () => context.pushNamed('forgot-password'),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterScreen(
          onNavigateToLogin: () => context.pushNamed('login'),
          onRegisterSuccess: () => context.goNamed('home'),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => ForgotPasswordScreen(
          onBackToLogin: () => context.goNamed('login'),
        ),
      ),
      GoRoute(
        path: '/reset-password/:token',
        name: 'reset-password',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordScreen(
            token: token,
            onBackToLogin: () => context.goNamed('login'),
          );
        },
      ),
      
      // Upgrade route (standalone, not in shell)
      GoRoute(
        path: '/upgrade',
        name: 'upgrade',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UpgradeScreen(),
      ),
      
      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _AppShell(child: child);
        },
        routes: [
          // Home route
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const _HomeScreen(),
            routes: [
              // Create poem route
              GoRoute(
                path: 'create',
                name: 'create',
                builder: (context, state) => const CreatePoemScreen(),
              ),
            ],
          ),
          
          // Gallery route
          GoRoute(
            path: '/gallery',
            name: 'gallery',
            builder: (context, state) => const _GalleryScreen(),
          ),
          
          // Profile route
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const _ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

// Temporary placeholder screens - these will be replaced with actual implementations
class _AppShell extends StatelessWidget {
  final Widget child;
  
  const _AppShell({required this.child});
  
  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Scaffold(
      backgroundColor: primaryBlack,
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryBlack,
        selectedItemColor: yellow,
        unselectedItemColor: sageGreen,
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  int _calculateSelectedIndex(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    final String location = router.routeInformationProvider.value.uri.path;
    if (location.startsWith('/gallery')) {
      return 1;
    } else if (location.startsWith('/profile')) {
      return 2;
    }
    return 0;
  }
  
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('home');
        break;
      case 1:
        context.goNamed('gallery');
        break;
      case 2:
        context.goNamed('profile');
        break;
    }
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();
  
  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Scaffold(
      backgroundColor: primaryBlack,
      appBar: AppBar(
        title: const Text('PoemVision AI'),
        backgroundColor: primaryBlack,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
              child: const Icon(
                Icons.auto_awesome,
                size: 64,
                color: yellow,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PoemVision AI',
              style: TextStyle(
                fontSize: 24,
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
            const SizedBox(height: 8),
            Text(
              'Free to use - No login required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: yellow,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.goNamed('create'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: blueGray,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create New Poem'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryScreen extends StatelessWidget {
  const _GalleryScreen();
  
  @override
  Widget build(BuildContext context) {
    return const GalleryScreen();
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();
  
  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
