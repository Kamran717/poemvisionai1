/// Route paths for the application
class RoutePaths {
  /// Private constructor to prevent instantiation
  RoutePaths._();
  
  /// Helper method to get poem customization path with analysis ID
  static String getPoemCustomizationPath(String analysisId) {
    return '$poemCustomization?analysis_id=$analysisId';
  }
  
  /// Login screen
  static const String login = '/login';
  
  /// Signup screen
  static const String signup = '/signup';
  
  /// Forgot password screen
  static const String forgotPassword = '/forgot-password';
  
  /// Reset password screen
  static const String resetPassword = '/reset-password';
  
  /// Splash screen
  static const String splash = '/splash';
  
  /// Introduction screen
  static const String intro = '/intro';
  
  /// Home screen
  static const String home = '/home';
  
  /// Gallery screen
  static const String gallery = '/gallery';
  
  /// Image upload screen
  static const String imageUpload = '/create/upload';
  
  /// Poem customization screen
  static const String poemCustomization = '/create/customize';
  
  /// Final creation screen
  static const String finalCreation = '/create/final';
  
  /// Profile screen
  static const String profile = '/profile';
  
  /// Edit profile screen
  static const String editProfile = '/profile/edit';
  
  /// Membership screen
  static const String membership = '/membership';
  
  /// Shared creation screen
  static const String sharedCreation = '/shared';
}
