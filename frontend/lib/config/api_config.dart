class ApiConfig {
  // Base URL for the PoemVision AI API
  // For local development, use: 'http://localhost:8000' or 'http://127.0.0.1:8000'
  // For production, use: 'https://poemvisionai.com'
  static const String baseUrl = 'https://poemvisionai.com';
  
  // API endpoints
  static const String apiBaseUrl = '$baseUrl/api';
  
  // Authentication endpoints
  static const String loginEndpoint = '$apiBaseUrl/auth/login';
  static const String registerEndpoint = '$apiBaseUrl/auth/register';
  static const String logoutEndpoint = '$apiBaseUrl/auth/logout';
  static const String refreshTokenEndpoint = '$apiBaseUrl/auth/refresh';
  
  // User endpoints
  static const String userProfileEndpoint = '$apiBaseUrl/user/profile';
  static const String updateProfileEndpoint = '$apiBaseUrl/user/update';
  
  // Poem generation endpoints
  static const String generatePoemEndpoint = '$baseUrl/generate-poem';
  static const String analyzeImageEndpoint = '$baseUrl/analyze-image';
  
  // Gallery endpoints
  static const String userPoemsEndpoint = '$apiBaseUrl/user/poems';
  static const String savePoemEndpoint = '$apiBaseUrl/poems/save';
  static const String deletePoemEndpoint = '$apiBaseUrl/poems/delete';
  
  // Membership endpoints
  static const String membershipStatusEndpoint = '$apiBaseUrl/membership/status';
  static const String upgradeEndpoint = '$apiBaseUrl/membership/upgrade';
  
  // Frame endpoints
  static const String framesEndpoint = '$apiBaseUrl/frames';
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
  
  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
