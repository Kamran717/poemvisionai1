/// Constants for API endpoints
class ApiConstants {
  /// Base URL
  static const String baseUrl = 'https://api.poemvision.ai';
  
  /// Auth endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  
  /// User profile endpoints
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String changePassword = '/users/change-password';
  
  /// Creation endpoints
  static const String creations = '/creations';
  static const String sharedCreation = '/creations/shared';
  
  /// Image processing endpoints
  static const String uploadImage = '/images/upload';
  static const String analyzeImage = '/images/analyze';
  
  /// Poem generation endpoints
  static const String generatePoem = '/poems/generate';
  static const String poems = '/poems';
  static const String finalCreation = '/creations/finalize';
  
  /// Membership endpoints
  static const String membershipPlans = '/memberships/plans';
  static const String cancelSubscription = '/memberships/cancel';
  
  /// Analytics endpoints
  static const String userAnalytics = '/analytics/user';
}
