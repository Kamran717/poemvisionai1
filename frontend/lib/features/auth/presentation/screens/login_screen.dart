import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/routes/route_paths.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/services/service_locator.dart';
import 'package:frontend/core/storage/secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiClient _apiClient = serviceLocator.get<ApiClient>();
  final SecureStorage _secureStorage = serviceLocator.get<SecureStorage>();
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      AppLogger.d('Logging in with email: $email');
      
      // TODO: Implement actual API call
      // This is a placeholder until we implement the actual API call
      // In a real implementation, we would call:
      // final response = await _apiClient.login(email: email, password: password);
      
      // For now, we'll simulate a successful response after a delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock response data for a successful login
      const mockToken = 'mock_token_12345';
      const mockUserInfo = {
        'id': 1,
        'username': 'poemuser',
        'email': 'user@example.com',
        'isPremium': false,
      };
      
      // Store the token and user info
      await _secureStorage.setAuthToken(mockToken);
      await _secureStorage.setUserInfo(mockUserInfo);
      
      // Navigate to home screen
      if (mounted) {
        context.go(RoutePaths.home);
      }
    } catch (e) {
      AppLogger.e('Error logging in: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    }
  }
  
  void _navigateToSignup() {
    AppLogger.d('Navigating to signup screen');
    context.go(RoutePaths.signup);
  }
  
  void _navigateToForgotPassword() {
    AppLogger.d('Navigating to forgot password screen');
    context.go(RoutePaths.forgotPassword);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and title
                const Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PoemVision AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Log in to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Login form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _navigateToForgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Login button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Logging in...'),
                                ],
                              )
                            : const Text('Log In'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Or divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.grey[400]),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Sign up button
                      OutlinedButton(
                        onPressed: _navigateToSignup,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Create New Account'),
                      ),
                      
                      // Demo Account
                      const SizedBox(height: 24),
                      const Text(
                        'Demo Account:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Email: demo@example.com\nPassword: demo123',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
