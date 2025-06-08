import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:frontend/features/auth/domain/services/auth_service.dart';
import 'package:frontend/core/utils/app_logger.dart';

/// Provider for authentication state and user information
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  // Authentication state
  AuthState _authState = AuthState.unknown;
  AuthState get authState => _authState;
  
  // User information
  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;
  
  // Subscription to auth state changes
  StreamSubscription<AuthState>? _authStateSubscription;
  
  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  AuthProvider(this._authService) {
    _init();
  }
  
  /// Initialize the provider
  Future<void> _init() async {
    try {
      // Subscribe to auth state changes
      _authStateSubscription = _authService.authStateStream.listen(_handleAuthStateChange);
      
      // Initialize auth service
      await _authService.init();
      
      // Get initial user if authenticated
      if (_authService.currentAuthState == AuthState.authenticated) {
        await _loadUserData();
      }
    } catch (e) {
      AppLogger.e('Error initializing auth provider', e);
      _setError('Failed to initialize authentication');
    }
  }
  
  /// Handle auth state changes
  void _handleAuthStateChange(AuthState state) async {
    _authState = state;
    
    if (state == AuthState.authenticated) {
      await _loadUserData();
    } else if (state == AuthState.unauthenticated) {
      _user = null;
    }
    
    notifyListeners();
  }
  
  /// Load user data
  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getCurrentUser();
      _user = userData;
    } catch (e) {
      AppLogger.e('Error loading user data', e);
      _setError('Failed to load user information');
    }
  }
  
  /// Login user
  Future<bool> login({required String email, required String password}) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.login(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      return result;
    } catch (e) {
      AppLogger.e('Error logging in', e);
      _setLoading(false);
      _setError('Invalid email or password');
      return false;
    }
  }
  
  /// Sign up user
  Future<bool> signup({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.signup(
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      
      _setLoading(false);
      return result;
    } catch (e) {
      AppLogger.e('Error signing up', e);
      _setLoading(false);
      _setError('Failed to create account. Please try again.');
      return false;
    }
  }
  
  /// Logout user
  Future<bool> logout() async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.logout();
      
      _setLoading(false);
      return result;
    } catch (e) {
      AppLogger.e('Error logging out', e);
      _setLoading(false);
      _setError('Failed to log out');
      return false;
    }
  }
  
  /// Request password reset
  Future<bool> forgotPassword({required String email}) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.forgotPassword(email: email);
      
      _setLoading(false);
      return result;
    } catch (e) {
      AppLogger.e('Error requesting password reset', e);
      _setLoading(false);
      _setError('Failed to send password reset email');
      return false;
    }
  }
  
  /// Reset password
  Future<bool> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      
      _setLoading(false);
      return result;
    } catch (e) {
      AppLogger.e('Error resetting password', e);
      _setLoading(false);
      _setError('Failed to reset password');
      return false;
    }
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
