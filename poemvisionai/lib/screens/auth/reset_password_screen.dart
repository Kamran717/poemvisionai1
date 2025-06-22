import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final VoidCallback onBackToLogin;

  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.onBackToLogin,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resetPassword(
        widget.token,
        _passwordController.text,
      );
      
      if (mounted) {
        setState(() {
          _successMessage = 'Your password has been updated successfully. You can now log in with your new password.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlack = Color(0xFF1B2A37);
    const Color blueGray = Color(0xFF7DA1BF);
    const Color yellow = Color(0xFFEDD050);
    const Color sageGreen = Color(0xFFC8C7B9);

    return Scaffold(
      backgroundColor: primaryBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: blueGray.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: blueGray, width: 2),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 50,
                      color: yellow,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'Enter your new password',
                    style: TextStyle(
                      fontSize: 16,
                      color: sageGreen.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Success message
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: widget.onBackToLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Go to Login'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Show form only if reset hasn't been successful
                  if (_successMessage == null) ...[
                    // New Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: sageGreen),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: blueGray, width: 2),
                        ),
                        prefixIcon: Icon(Icons.lock, color: blueGray),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: blueGray,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: sageGreen.withOpacity(0.1),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(color: sageGreen),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: sageGreen.withOpacity(0.3)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: blueGray, width: 2),
                        ),
                        prefixIcon: Icon(Icons.lock, color: blueGray),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: blueGray,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: sageGreen.withOpacity(0.1),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Reset password button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: blueGray,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Update Password'),
                    ),
                    const SizedBox(height: 24),
                    
                    // Back to login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Remember your password?",
                          style: TextStyle(color: sageGreen.withOpacity(0.8)),
                        ),
                        TextButton(
                          onPressed: widget.onBackToLogin,
                          child: Text(
                            'Back to Login',
                            style: TextStyle(color: yellow),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
