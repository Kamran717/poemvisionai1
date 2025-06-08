import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiService _apiService;
  User? _currentUser;
  final StreamController<User?> _userStreamController = StreamController<User?>.broadcast();

  // Access to the user stream for state management
  Stream<User?> get userStream => _userStreamController.stream;
  
  // Current user getter
  User? get currentUser => _currentUser;
  
  // Token keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  AuthService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  // Initialize the auth service by checking for existing token
  Future<bool> initialize() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null) {
      try {
        // Create a new API service with the token
        final apiService = ApiService(token: token);
        
        // Try to get the user profile to validate the token
        final user = await apiService.getUserProfile();
        
        _currentUser = user;
        _userStreamController.add(user);
        return true;
      } catch (e) {
        // Token might be expired, clear it
        await logout();
        return false;
      }
    }
    return false;
  }

  // Login user with email and password
  Future<User> login(String email, String password) async {
    final response = await _apiService.login(email, password);
    
    // Save the tokens to secure storage
    await _secureStorage.write(key: _tokenKey, value: response['token']);
    if (response['refresh_token'] != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: response['refresh_token']);
    }
    if (response['user_id'] != null) {
      await _secureStorage.write(key: _userIdKey, value: response['user_id'].toString());
    }
    
    // Get user profile with the new token
    final apiService = ApiService(token: response['token']);
    final user = await apiService.getUserProfile();
    
    _currentUser = user;
    _userStreamController.add(user);
    
    return user;
  }

  // Register a new user
  Future<User> register(String username, String email, String password) async {
    final response = await _apiService.register(username, email, password);
    
    // If registration returns a token, save it
    if (response['token'] != null) {
      await _secureStorage.write(key: _tokenKey, value: response['token']);
      if (response['refresh_token'] != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: response['refresh_token']);
      }
      if (response['user_id'] != null) {
        await _secureStorage.write(key: _userIdKey, value: response['user_id'].toString());
      }
      
      // Get user profile with the new token
      final apiService = ApiService(token: response['token']);
      final user = await apiService.getUserProfile();
      
      _currentUser = user;
      _userStreamController.add(user);
      
      return user;
    } else {
      // Registration might require email verification
      throw Exception('Registration successful, but no token received. Email verification may be required.');
    }
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    await _apiService.requestPasswordReset(email);
  }

  // Log out user
  Future<void> logout() async {
    // Clear secure storage
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    
    // Clear current user
    _currentUser = null;
    _userStreamController.add(null);
  }

  // Get current token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null;
  }

  // Refresh the user data
  Future<User?> refreshUserData() async {
    try {
      final token = await getToken();
      if (token != null) {
        final apiService = ApiService(token: token);
        final user = await apiService.getUserProfile();
        
        _currentUser = user;
        _userStreamController.add(user);
        
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Dispose resources
  void dispose() {
    _userStreamController.close();
  }
}
