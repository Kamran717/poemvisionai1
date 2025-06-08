/// Constants for API endpoints and related values
class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();
  
  // Base URL for API requests
  static const String baseUrl = 'http://localhost:5000';
  
  // Authentication endpoints
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String logout = '/logout';
  static const String verifyEmail = '/verify-email';
  
  // User related endpoints
  static const String profile = '/profile';
  
  // Image processing endpoints
  static const String analyzeImage = '/analyze-image';
  static const String generatePoem = '/generate-poem';
  static const String createFinalImage = '/create-final-image';
  
  // Gallery and creations
  static const String gallery = '/gallery';
  static const String shared = '/shared';
  static const String deleteCreation = '/delete_creation';
  
  // Features and membership
  static const String availablePoemTypes = '/api/available-poem-types';
  static const String availablePoemLengths = '/api/available-poem-lengths';
  static const String availableFrames = '/api/available-frames';
  static const String membership = '/membership';
  static const String upgrade = '/upgrade';
  static const String checkAccess = '/api/check-access';
  
  // HTTP status codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusInternalServerError = 500;
  
  // Request timeouts in seconds
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;
}
