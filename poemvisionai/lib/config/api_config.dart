class ApiConfig {
  // Base URL for the PoemVision AI API
  // For local development, use: 'http://localhost:8000' or 'http://127.0.0.1:8000'
  // For production, use: 'https://poemvisionai.com'
  static const String baseUrl = 'https://poemvisionai.com';
  
  // Authentication endpoints (matching Flask routes)
  static const String loginEndpoint = '$baseUrl/login';
  static const String registerEndpoint = '$baseUrl/signup';
  static const String logoutEndpoint = '$baseUrl/logout';
  static const String forgotPasswordEndpoint = '$baseUrl/forgot-password';
  
  // User endpoints  
  static const String userProfileEndpoint = '$baseUrl/profile';
  
  // Poem generation endpoints
  static const String generatePoemEndpoint = '$baseUrl/generate-poem';
  static const String analyzeImageEndpoint = '$baseUrl/analyze-image';
  static const String createFinalImageEndpoint = '$baseUrl/create-final-image';
  
  // Gallery endpoints
  static const String userPoemsEndpoint = '$baseUrl/profile'; // Flask uses profile for user creations
  
  // Membership endpoints
  static const String membershipPlansEndpoint = '$baseUrl/membership';
  static const String upgradeEndpoint = '$baseUrl/upgrade';
  static const String cancelSubscriptionEndpoint = '$baseUrl/cancel-subscription';
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
  
  // Form headers for Flask compatibility
  static Map<String, String> get formHeaders => {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Accept': 'application/json',
  };
  
  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
