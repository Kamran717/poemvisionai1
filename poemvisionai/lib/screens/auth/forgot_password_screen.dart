import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBackToLogin;

  const ForgotPasswordScreen({
    super.key,
    required this.onBackToLogin,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
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
      await authService.requestPasswordReset(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _successMessage = 'If an account exists with this email, a password reset link has been sent. Please check your inbox.';
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
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: widget.onBackToLogin,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
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
                    'Forgot Password?',
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
                    'Enter your email address and we\'ll send you a link to reset your password',
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
                          TextButton(
                            onPressed: widget.onBackToLogin,
                            child: Text(
                              'Back to Login',
                              style: TextStyle(color: yellow),
                            ),
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
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
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
                      prefixIcon: Icon(Icons.email, color: blueGray),
                      filled: true,
                      fillColor: sageGreen.withOpacity(0.1),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Reset password button
                  ElevatedButton(
                    onPressed: _isLoading || _successMessage != null ? null : _requestPasswordReset,
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
                        : const Text('Send Reset Link'),
                  ),
                  const SizedBox(height: 24),
                  
                  // Back to login link
                  if (_successMessage == null) ...[
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
