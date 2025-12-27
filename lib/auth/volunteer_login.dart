import 'dart:convert';
import 'package:volunteer_app/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/auth/volunteer_signup.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/widgets/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = '';
  String role = 'volunteer';
  String password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _onLoginPressed(
    String email,
    String password,
    String role,
  ) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both email and password');
      return;
    } else if (role.isEmpty) {
      _showErrorDialog('User role is not selected');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Make API call to login endpoint
      final response = await http.post(
        Uri.parse('$kBaseUrl/public/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'role': role}),
      );

      if (response.statusCode == 200) {
        // Parse response
        final data = jsonDecode(response.body);

        // 🔍 DEBUG: Print the entire response
        // print('==================== LOGIN RESPONSE ====================');
        // print('Full response: $data');
        // print('Token: ${data['token']}');
        // print('ID field: ${data['id']}');
        // print('UserId field: ${data['userId']}');
        // print('Data field: ${data['data']}');
        // print('=======================================================');

        // Store token and user data
        final prefs = await SharedPreferences.getInstance();

        // Clear old data first
        await prefs.clear();

        // Save token using the constant from env.dart
        await prefs.setString(kTokenStorageKey, data['token'] ?? '');

        // Try multiple possible locations for user ID
        String? userId;
        if (data['id'] != null) {
          userId = data['id'].toString();
        } else if (data['userId'] != null) {
          userId = data['userId'].toString();
        } else if (data['data'] != null && data['data']['id'] != null) {
          userId = data['data']['id'].toString();
        }

        if (userId != null) {
          await prefs.setString('user_id', userId);
        }

        String? role;
        if (data['role'] != null) {
          role = data['role'].toString();
          if (role != null) {
            await prefs.setString('role', role);
          }
          if (role == 'volunteer') {
            return;
          }
        }

        // Save alternate token key for Edit Profile compatibility
        await prefs.setString(kTokenStorageKey, data['token'] ?? '');
        await prefs.setString('email', email);

        // 🔍 DEBUG: Verify what was saved
        // print('==================== SAVED TO STORAGE ====================');
        // print('All keys: ${prefs.getKeys()}');
        // print('Token (kTokenStorageKey): ${prefs.getString(kTokenStorageKey)}');
        // print('User ID: ${prefs.getString('user_id')}');
        // print('Auth token: ${prefs.getString('auth_token')}');
        // print('Email: ${prefs.getString('email')}');
        // print('=======================================================');

        // Navigate to home screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        // Try to parse error, but handle HTML responses
        try {
          final error = jsonDecode(response.body);
          _showErrorDialog(error['message'] ?? 'Login failed');
        } catch (e) {
          _showErrorDialog(
            'Server error: ${response.statusCode}\n${response.body.substring(0, 100)}',
          );
        }
      }
    } catch (e) {
      print('Error details: $e');
      _showErrorDialog(
        'Network error: Please check your connection and server URL',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onForgotPassword() async {
    final emailController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email address and we\'ll send you instructions to reset your password.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: "Email",
                  labelText: "Email",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 116, 188, 247),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final resetEmail = emailController.text.trim();

                      if (resetEmail.isEmpty) {
                        _showErrorDialog('Please enter your email address');
                        return;
                      }

                      // Email validation
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(resetEmail)) {
                        _showErrorDialog('Please enter a valid email address');
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        // Make API call to forgot password endpoint
                        final response = await http.post(
                          Uri.parse('$kBaseUrl/public/forgot-password'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'email': resetEmail}),
                        );

                        if (mounted) {
                          Navigator.of(context).pop(); // Close dialog
                        }

                        if (response.statusCode == 200) {
                          _showSuccessDialog(
                            'Password reset instructions have been sent to $resetEmail',
                          );
                        } else {
                          try {
                            final error = jsonDecode(response.body);
                            _showErrorDialog(
                              error['message'] ?? 'Failed to send reset email',
                            );
                          } catch (e) {
                            _showErrorDialog(
                              'Failed to send reset email. Please try again.',
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(context).pop(); // Close dialog
                        }
                        _showErrorDialog(
                          'Network error: Please check your connection',
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Title
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/images/logo5.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: AppTheme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue making a difference',
                  style: AppTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Form
                TextFormField(
                  onChanged: (value) => setState(() => email = value),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  onChanged: (value) => setState(() => password = value),
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Forgot Password Placeholder (Commented out in original)
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: TextButton(
                //     onPressed: _onForgotPassword,
                //     child: const Text('Forgot Password?'),
                //   ),
                // ),
                const SizedBox(height: 32),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _onLoginPressed(email, password, role),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Log In'),
                ),

                const SizedBox(height: 24),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTheme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
