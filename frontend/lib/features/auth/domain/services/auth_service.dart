import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/network/api_client.dart';

/// Authentication response model
class AuthResponse {
  /// Auth token
  final String token;
  
  /// User ID
  final String userId;
  
  /// Constructor
  AuthResponse({
    required this.token,
    required this.userId,
  });
}

/// Authentication service
class AuthService {
  /// API client
  final ApiClient _apiClient;
  
  /// Secure storage for tokens
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Token storage key
  static const String _tokenKey = 'auth_token';
  
  /// User ID storage key
  static const String _userIdKey = 'user_id';
  
  /// Constructor
  AuthService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  
  /// Set auth token in API client
  void setToken(String token) {
    _apiClient.setToken(token);
  }
  
  /// Clear auth token in API client
  void clearToken() {
    _apiClient.clearToken();
  }
  
  /// Store auth token securely
  Future<void> storeToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }
  
  /// Get stored auth token
  Future<String?> getStoredToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  
  /// Clear stored auth token
  Future<void> clearStoredToken() async {
    await _secureStorage.delete(key: _tokenKey);
    
    // Also clear user ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
  
  /// Store user ID
  Future<void> storeUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }
  
  /// Get stored user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  /// Validate auth token
  Future<bool> validateToken(String token) async {
    try {
      // In a real app, we would validate the token with the server
      // For now, just return true if token exists
      return token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final token = response['token'] as String;
      final userId = response['user_id'] as String;
      
      // Store user ID
      await storeUserId(userId);
      
      return AuthResponse(
        token: token,
        userId: userId,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Register a new user
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/signup',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      
      final token = response['token'] as String;
      final userId = response['user_id'] as String;
      
      // Store user ID
      await storeUserId(userId);
      
      return AuthResponse(
        token: token,
        userId: userId,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    }
  }
  
  /// Request password reset
  Future<void> forgotPassword({
    required String email,
  }) async {
    await _apiClient.post(
      '/auth/forgot-password',
      data: {
        'email': email,
      },
    );
  }
  
  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    await _apiClient.post(
      '/auth/reset-password',
      data: {
        'token': token,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );
  }
}
