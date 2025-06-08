import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/features/auth/presentation/guards/auth_guard.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/auth/presentation/screens/signup_screen.dart';
import 'package:frontend/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:frontend/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:frontend/features/image_processing/presentation/screens/image_upload_screen.dart';
import 'package:frontend/features/poem_generation/presentation/screens/poem_customization_screen.dart';
import 'package:frontend/features/poem_generation/presentation/screens/final_creation_screen.dart';
import 'package:frontend/features/gallery/presentation/screens/gallery_screen.dart';
import 'package:frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:frontend/presentation/screens/home_screen.dart';
import 'package:frontend/presentation/screens/intro_screen.dart';
import 'package:frontend/presentation/screens/splash_screen.dart';
import 'package:frontend/presentation/screens/shared_creation_screen.dart';

/// Router configuration for the app
class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();
  
  /// The main router instance
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      // Public routes (no authentication required)
      
      // Splash and intro
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.intro,
        builder: (context, state) => const IntroScreen(),
      ),
      
      // Authentication
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
        redirect: AuthGuard.loginGuard,
      ),
      GoRoute(
        path: RoutePaths.signup,
        builder: (context, state) => const SignupScreen(),
        redirect: AuthGuard.loginGuard,
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      
      // Shared creation (public)
      GoRoute(
        path: '${RoutePaths.shared}/:shareCode',
        builder: (context, state) {
          final shareCode = state.pathParameters['shareCode'] ?? '';
          return SharedCreationScreen(shareCode: shareCode);
        },
      ),
      
      // Protected routes (authentication required)
      
      // Main app screens
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
        redirect: AuthGuard.guard,
      ),
      
      // Image processing and poem generation
      GoRoute(
        path: RoutePaths.imageUpload,
        builder: (context, state) => const ImageUploadScreen(),
        redirect: AuthGuard.guard,
      ),
      GoRoute(
        path: RoutePaths.poemCustomization,
        builder: (context, state) {
          final analysisId = state.pathParameters['analysisId'] ?? '';
          return PoemCustomizationScreen(analysisId: analysisId);
        },
        redirect: AuthGuard.guard,
      ),
      GoRoute(
        path: RoutePaths.finalCreation,
        builder: (context, state) {
          final analysisId = state.pathParameters['analysisId'] ?? '';
          return FinalCreationScreen(analysisId: analysisId);
        },
        redirect: AuthGuard.guard,
      ),
      
      // Gallery and profile
      GoRoute(
        path: RoutePaths.gallery,
        builder: (context, state) => const GalleryScreen(),
        redirect: AuthGuard.guard,
      ),
      GoRoute(
        path: RoutePaths.profile,
        builder: (context, state) => const ProfileScreen(),
        redirect: AuthGuard.guard,
      ),
    ],
    
    // Error handler
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Oops! The page you\'re looking for doesn\'t exist.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    
    // Redirect logic for initial auth check
    redirect: (context, state) async {
      // Skip redirect for these paths
      if (state.fullPath == RoutePaths.splash ||
          state.fullPath == RoutePaths.intro ||
          state.fullPath == RoutePaths.login ||
          state.fullPath == RoutePaths.signup ||
          state.fullPath == RoutePaths.forgotPassword ||
          state.fullPath?.startsWith(RoutePaths.resetPassword) == true ||
          state.fullPath?.startsWith(RoutePaths.shared) == true) {
        return null;
      }
      
      // For other paths, check intro and authentication
      return await AuthGuard.introGuard(context, state);
    },
  );
  
  /// Navigate to a route with fade transition
  static void navigateWithFade(BuildContext context, String route) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return router.routeInformationParser
              .parseRouteInformation(RouteInformation(location: route))
              .then((configuration) {
            return router.routerDelegate.build(
              BuildContext,
            ) as Widget;
          }) as Widget;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
