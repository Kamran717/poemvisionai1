import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/features/auth/domain/services/auth_service.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/core/utils/app_logger.dart';

/// Guard to protect routes that require authentication
class AuthGuard {
  /// Check if the user is authenticated and redirect to login if not
  static Future<String?> guard(
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Check if the user is authenticated
      final isAuthenticated = await authProvider.isAuthenticated;
      
      // If not authenticated, redirect to login
      if (!isAuthenticated) {
        AppLogger.d('User is not authenticated, redirecting to login');
        return RoutePaths.login;
      }
      
      // User is authenticated, allow access to the route
      return null;
    } catch (e) {
      AppLogger.e('Error in auth guard', e);
      // If there's an error, redirect to login as a fallback
      return RoutePaths.login;
    }
  }
  
  /// Check if user is already authenticated and redirect to home if so
  static Future<String?> loginGuard(
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Check if the user is already authenticated
      final isAuthenticated = await authProvider.isAuthenticated;
      
      // If already authenticated, redirect to home
      if (isAuthenticated) {
        AppLogger.d('User is already authenticated, redirecting to home');
        return RoutePaths.home;
      }
      
      // User is not authenticated, allow access to login/signup screens
      return null;
    } catch (e) {
      AppLogger.e('Error in login guard', e);
      // If there's an error, still allow access to login screen
      return null;
    }
  }
  
  /// Middleware for checking if the intro screen has been shown
  static Future<String?> introGuard(
    BuildContext context,
    GoRouterState state,
  ) async {
    try {
      // Check if intro has been shown
      final prefs = await SharedPreferences.getInstance();
      final introShown = prefs.getBool('intro_shown') ?? false;
      
      // If intro hasn't been shown, redirect to intro
      if (!introShown) {
        AppLogger.d('Intro not shown, redirecting to intro');
        return RoutePaths.intro;
      }
      
      // Intro has been shown, proceed with auth check
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = await authProvider.isAuthenticated;
      
      // If not authenticated, redirect to login
      if (!isAuthenticated) {
        AppLogger.d('User is not authenticated, redirecting to login');
        return RoutePaths.login;
      }
      
      // User is authenticated, allow access to the route
      return null;
    } catch (e) {
      AppLogger.e('Error in intro guard', e);
      // If there's an error, redirect to intro as a fallback
      return RoutePaths.intro;
    }
  }
}
