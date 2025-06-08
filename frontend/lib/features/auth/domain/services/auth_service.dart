import 'dart:async';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/core/utils/app_logger.dart';

/// Service responsible for authentication operations
class AuthService {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  
  // Auth state stream
  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  // Current auth state
  AuthState _currentAuthState = AuthState.unknown;
  AuthState get currentAuthState => _currentAuthState;
  
  AuthService(this._apiClient, this._secureStorage);
  
  /// Initialize the auth service
  Future<void> init() async {
    try {
      // Check if user is logged in
      final token = await _secureStorage.getAuthToken();
      
      if (token != null && token.isNotEmpty) {
        // Token exists, user is authenticated
        final userInfo = await _secureStorage.getUserInfo();
        
        if (userInfo != null) {
          _updateAuthState(AuthState.authenticated);
        } else {
          // Token exists but no user info, something is wrong
          await _secureStorage.clearAuthData();
          _updateAuthState(AuthState.unauthenticated);
        }
      } else {
        // No token, user is not authenticated
        _updateAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      AppLogger.e('Error initializing auth service', e);
      _updateAuthState(AuthState.unauthenticated);
    }
  }
  
  /// Login user
  Future<bool> login({required String email, required String password}) async {
    try {
      // Call API to login
      final response = await _apiClient.login(
        email: email,
        password: password,
      );
      
      if (response.isSuccess && response.data != null) {
        // Extract token and user info from response
        final responseData = response.data!;
        final token = responseData['token'] as String;
        final userInfo = responseData['user'] as Map<String, dynamic>;
        
        // Store token and user info
        await _secureStorage.setAuthToken(token);
        await _secureStorage.setUserInfo(userInfo);
        
        // Update auth state
        _updateAuthState(AuthState.authenticated);
        
        return true;
      } else {
        throw Exception(response.error?.message ?? 'Failed to login');
      }
    } catch (e) {
      AppLogger.e('Error logging in', e);
      _updateAuthState(AuthState.unauthenticated);
      rethrow;
    }
  }
  
  /// Register new user
  Future<bool> signup({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // Call API to register
      final response = await _apiClient.signup(
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      
      if (response.isSuccess && response.data != null) {
        // Extract token and user info from response
        final responseData = response.data!;
        final token = responseData['token'] as String;
        final userInfo = responseData['user'] as Map<String, dynamic>;
        
        // Store token and user info
        await _secureStorage.setAuthToken(token);
        await _secureStorage.setUserInfo(userInfo);
        
        // Update auth state
        _updateAuthState(AuthState.authenticated);
        
        return true;
      } else {
        throw Exception(response.error?.message ?? 'Failed to signup');
      }
    } catch (e) {
      AppLogger.e('Error signing up', e);
      _updateAuthState(AuthState.unauthenticated);
      rethrow;
    }
  }
  
  /// Logout user
  Future<bool> logout() async {
    try {
      // Call API to logout
      // final response = await _apiClient.logout();
      
      // Clear stored data
      await _secureStorage.clearAuthData();
      
      // Update auth state
      _updateAuthState(AuthState.unauthenticated);
      
      return true;
    } catch (e) {
      AppLogger.e('Error logging out', e);
      // Still clear local data even if API call fails
      await _secureStorage.clearAuthData();
      _updateAuthState(AuthState.unauthenticated);
      return false;
    }
  }
  
  /// Request password reset
  Future<bool> forgotPassword({required String email}) async {
    try {
      // Call API to request password reset
      final response = await _apiClient.post(
        '/forgot-password',
        data: {'email': email},
      );
      
      return response.isSuccess;
    } catch (e) {
      AppLogger.e('Error requesting password reset', e);
      rethrow;
    }
  }
  
  /// Reset password
  Future<bool> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // Call API to reset password
      final response = await _apiClient.post(
        '/reset-password',
        data: {
          'token': token,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );
      
      return response.isSuccess;
    } catch (e) {
      AppLogger.e('Error resetting password', e);
      rethrow;
    }
  }
  
  /// Get current user information
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      if (_currentAuthState != AuthState.authenticated) {
        return null;
      }
      
      return await _secureStorage.getUserInfo();
    } catch (e) {
      AppLogger.e('Error getting current user', e);
      return null;
    }
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _secureStorage.getAuthToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      AppLogger.e('Error checking authentication status', e);
      return false;
    }
  }
  
  /// Refresh token if needed
  Future<bool> refreshTokenIfNeeded() async {
    // TODO: Implement token refresh logic
    return true;
  }
  
  /// Update auth state and notify listeners
  void _updateAuthState(AuthState newState) {
    _currentAuthState = newState;
    _authStateController.add(newState);
    AppLogger.d('Auth state updated: $newState');
  }
  
  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}

/// Authentication states
enum AuthState {
  /// Initial state, auth status not determined yet
  unknown,
  
  /// User is authenticated
  authenticated,
  
  /// User is not authenticated
  unauthenticated,
}
