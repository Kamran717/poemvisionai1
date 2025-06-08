/// Route paths for the application
class RoutePaths {
  /// Private constructor to prevent instantiation
  RoutePaths._();
  
  /// Splash screen
  static const String splash = '/splash';
  
  /// Intro screen
  static const String intro = '/intro';
  
  /// Home screen
  static const String home = '/';
  
  /// Authentication routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  
  /// User profile routes
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  
  /// Membership routes
  static const String membership = '/membership';
  
  /// Poem creation routes
  static const String imageUpload = '/create/upload';
  static const String poemCustomization = '/create/customize';
  static const String finalCreation = '/create/finalize';
  
  /// Gallery routes
  static const String gallery = '/gallery';
  static const String sharedCreation = '/shared';
}
