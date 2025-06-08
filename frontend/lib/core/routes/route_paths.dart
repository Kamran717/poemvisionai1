/// Constants for route paths used in the app
class RoutePaths {
  // Private constructor to prevent instantiation
  RoutePaths._();
  
  // Splash and onboarding
  static const String splash = '/splash';
  static const String intro = '/intro';
  
  // Main app screens
  static const String home = '/';
  
  // Authentication
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password/:token';
  
  // Image processing and poem generation
  static const String imageUpload = '/image-upload';
  static const String poemCustomization = '/poem-customization/:analysisId';
  static const String finalCreation = '/final-creation/:analysisId';
  
  // Gallery and profile
  static const String gallery = '/gallery';
  static const String profile = '/profile';
  
  // Shared creation
  static const String shared = '/shared';
  
  // Settings
  static const String settings = '/settings';
  
  // About
  static const String about = '/about';
  
  // Terms and privacy
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  
  // Helper methods to get dynamic paths
  
  /// Get the poem customization path with the analysis ID
  static String getPoemCustomizationPath(String analysisId) {
    return '/poem-customization/$analysisId';
  }
  
  /// Get the final creation path with the analysis ID
  static String getFinalCreationPath(String analysisId) {
    return '/final-creation/$analysisId';
  }
  
  /// Get the shared creation path with the share code
  static String getSharedCreationPath(String shareCode) {
    return '/shared/$shareCode';
  }
  
  /// Get the reset password path with the token
  static String getResetPasswordPath(String token) {
    return '/reset-password/$token';
  }
}
