import 'package:flutter/foundation.dart';
import 'package:frontend/features/auth/domain/services/auth_service.dart';

/// Authentication provider
class AuthProvider extends ChangeNotifier {
  /// Auth service
  final AuthService _authService;
  
  /// Whether the user is authenticated
  bool _isAuthenticated = false;
  
  /// Auth token
  String? _token;
  
  /// User ID
  String? _userId;
  
  /// Constructor
  AuthProvider({
    required AuthService authService,
  }) : _authService = authService;
  
  /// Get authentication status
  bool get isAuthenticated => _isAuthenticated;
  
  /// Get auth token
  String? get token => _token;
  
  /// Get user ID
  String? get userId => _userId;
  
  /// Initialize authentication state from stored token
  Future<void> initializeAuthState() async {
    try {
      final storedToken = await _authService.getStoredToken();
      if (storedToken != null) {
        _token = storedToken;
        _isAuthenticated = true;
        
        // Set token in API client
        _authService.setToken(storedToken);
        
        // Get user ID
        final userId = await _authService.getUserId();
        _userId = userId;
        
        notifyListeners();
      }
    } catch (e) {
      // Clear auth state on error
      _clearAuthState();
      rethrow;
    }
  }
  
  /// Check if user is authenticated
  Future<bool> checkAuthentication() async {
    try {
      final storedToken = await _authService.getStoredToken();
      if (storedToken != null) {
        // Validate token
        final isValid = await _authService.validateToken(storedToken);
        if (isValid) {
          _token = storedToken;
          _isAuthenticated = true;
          
          // Set token in API client
          _authService.setToken(storedToken);
          
          // Get user ID
          final userId = await _authService.getUserId();
          _userId = userId;
          
          notifyListeners();
          return true;
        }
      }
      
      // Clear auth state if token is invalid or not found
      _clearAuthState();
      return false;
    } catch (e) {
      // Clear auth state on error
      _clearAuthState();
      return false;
    }
  }
  
  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );
      
      _token = result.token;
      _userId = result.userId;
      _isAuthenticated = true;
      
      // Set token in API client
      _authService.setToken(_token!);
      
      // Store token
      await _authService.storeToken(_token!);
      
      notifyListeners();
      return true;
    } catch (e) {
      _clearAuthState();
      rethrow;
    }
  }
  
  /// Register a new user
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authService.signup(
        name: name,
        email: email,
        password: password,
      );
      
      _token = result.token;
      _userId = result.userId;
      _isAuthenticated = true;
      
      // Set token in API client
      _authService.setToken(_token!);
      
      // Store token
      await _authService.storeToken(_token!);
      
      notifyListeners();
      return true;
    } catch (e) {
      _clearAuthState();
      rethrow;
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      // Clear auth state regardless of API call result
      await _clearAuthState();
    }
  }
  
  /// Request password reset
  Future<void> forgotPassword({
    required String email,
  }) async {
    await _authService.forgotPassword(email: email);
  }
  
  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _authService.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Clear authentication state
  Future<void> _clearAuthState() async {
    _token = null;
    _userId = null;
    _isAuthenticated = false;
    
    // Clear token in API client
    _authService.clearToken();
    
    // Clear stored token
    await _authService.clearStoredToken();
    
    notifyListeners();
  }
}
