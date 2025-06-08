import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth result model
class AuthResult {
  /// Authentication token
  final String token;
  
  /// User ID
  final String userId;
  
  /// Constructor
  AuthResult({
    required this.token,
    required this.userId,
  });
}

/// Authentication service
abstract class AuthService {
  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  });
  
  /// Register a new user
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  });
  
  /// Logout
  Future<void> logout();
  
  /// Request password reset
  Future<void> forgotPassword({
    required String email,
  });
  
  /// Reset password
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  });
  
  /// Validate token
  Future<bool> validateToken(String token);
  
  /// Get stored token
  Future<String?> getStoredToken();
  
  /// Store token
  Future<void> storeToken(String token);
  
  /// Clear stored token
  Future<void> clearStoredToken();
  
  /// Set token in API client
  void setToken(String token);
  
  /// Clear token in API client
  void clearToken();
  
  /// Get user ID from token
  Future<String?> getUserId();
}

/// Implementation of authentication service
class AuthServiceImpl implements AuthService {
  /// Token storage key
  static const String _tokenKey = 'auth_token';
  
  /// API base URL
  final String _apiBaseUrl;
  
  /// Current token
  String? _currentToken;
  
  /// Constructor
  AuthServiceImpl({
    required String apiBaseUrl,
  }) : _apiBaseUrl = apiBaseUrl;
  
  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
    
    // Generate mock token
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    
    return AuthResult(
      token: token,
      userId: userId,
    );
  }
  
  @override
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
    
    // Generate mock token
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    
    return AuthResult(
      token: token,
      userId: userId,
    );
  }
  
  @override
  Future<void> logout() async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Clear token
    _currentToken = null;
  }
  
  @override
  Future<void> forgotPassword({
    required String email,
  }) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
  }
  
  @override
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
    
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }
  }
  
  @override
  Future<bool> validateToken(String token) async {
    // TODO: Implement API call
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Always valid for mock
    return true;
  }
  
  @override
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  @override
  Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  @override
  Future<void> clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  @override
  void setToken(String token) {
    _currentToken = token;
    // Set token in API client headers
  }
  
  @override
  void clearToken() {
    _currentToken = null;
    // Clear token from API client headers
  }
  
  @override
  Future<String?> getUserId() async {
    // TODO: Implement JWT decode or API call
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_currentToken == null) {
      return null;
    }
    
    // Extract user ID from token (mock)
    return 'user_123';
  }
}
