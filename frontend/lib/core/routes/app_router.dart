import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/auth/presentation/screens/signup_screen.dart';
import 'package:frontend/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:frontend/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/home/presentation/screens/intro_screen.dart';
import 'package:frontend/features/home/presentation/screens/splash_screen.dart';
import 'package:frontend/features/gallery/presentation/screens/gallery_screen.dart';
import 'package:frontend/features/poem_generation/presentation/screens/image_upload_screen.dart';
import 'package:frontend/features/poem_generation/presentation/screens/poem_customization_screen.dart';
import 'package:frontend/features/poem_generation/presentation/screens/final_creation_screen.dart';
import 'package:frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:frontend/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:frontend/features/profile/presentation/screens/membership_screen.dart';

/// Router configuration for the app
class AppRouter {
  /// Whether the user is authenticated
  final bool isAuthenticated;
  
  /// Router instance
  final GoRouter _router;
  
  /// Private constructor
  AppRouter._({
    required this.isAuthenticated,
    required GoRouter router,
  }) : _router = router;
  
  /// Create a new router
  static AppRouter create({
    required bool isAuthenticated,
  }) {
    final router = GoRouter(
      initialLocation: isAuthenticated ? RoutePaths.home : RoutePaths.splash,
      debugLogDiagnostics: true,
      routes: [
        // Auth routes
        GoRoute(
          path: RoutePaths.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RoutePaths.signup,
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: RoutePaths.forgotPassword,
          name: 'forgot_password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: RoutePaths.resetPassword,
          name: 'reset_password',
          builder: (context, state) {
            final params = GoRouterState.of(context).uri.queryParameters;
            final token = params['token'] ?? '';
            return ResetPasswordScreen(token: token);
          },
        ),
        
        // Main routes
        GoRoute(
          path: RoutePaths.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: RoutePaths.intro,
          name: 'intro',
          builder: (context, state) => const IntroScreen(),
        ),
        GoRoute(
          path: RoutePaths.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        
        // Gallery routes
        GoRoute(
          path: RoutePaths.gallery,
          name: 'gallery',
          builder: (context, state) => const GalleryScreen(),
        ),
        
        // Poem creation routes
        GoRoute(
          path: RoutePaths.imageUpload,
          name: 'image_upload',
          builder: (context, state) => const ImageUploadScreen(),
        ),
        GoRoute(
          path: RoutePaths.poemCustomization,
          name: 'poem_customization',
          builder: (context, state) {
            final params = GoRouterState.of(context).uri.queryParameters;
            final imageId = params['image_id'] ?? '';
            final analysisId = params['analysis_id'] ?? '';
            return PoemCustomizationScreen(
              imageId: imageId,
              analysisId: analysisId,
            );
          },
        ),
        GoRoute(
          path: RoutePaths.finalCreation,
          name: 'final_creation',
          builder: (context, state) {
            final params = GoRouterState.of(context).uri.queryParameters;
            final poemId = params['poem_id'] ?? '';
            return FinalCreationScreen(poemId: poemId);
          },
        ),
        
        // Profile routes
        GoRoute(
          path: RoutePaths.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: RoutePaths.editProfile,
          name: 'edit_profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: RoutePaths.membership,
          name: 'membership',
          builder: (context, state) => const MembershipScreen(),
        ),
        
        // Shared creation
        GoRoute(
          path: RoutePaths.sharedCreation,
          name: 'shared_creation',
          builder: (context, state) {
            final params = GoRouterState.of(context).uri.queryParameters;
            final shareId = params['id'] ?? '';
            return FinalCreationScreen(
              sharedId: shareId,
              isShared: true,
            );
          },
        ),
      ],
      // Redirect unauthenticated users to login
      redirect: (context, state) {
        // Public routes that don't require authentication
        final publicRoutes = [
          RoutePaths.login,
          RoutePaths.signup,
          RoutePaths.forgotPassword,
          RoutePaths.resetPassword,
          RoutePaths.splash,
          RoutePaths.intro,
          RoutePaths.sharedCreation,
        ];
        
        // Allow access to public routes
        if (publicRoutes.contains(state.matchedLocation)) {
          return null;
        }
        
        // Redirect to login if not authenticated
        if (!isAuthenticated) {
          return RoutePaths.login;
        }
        
        // Allow access to all routes if authenticated
        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text(
            'Page not found: ${state.error}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
    
    return AppRouter._(
      isAuthenticated: isAuthenticated,
      router: router,
    );
  }
  
  /// Get the router instance
  GoRouter getRouter() => _router;
  
  /// Router getter
  GoRouter get router => _router;
}
