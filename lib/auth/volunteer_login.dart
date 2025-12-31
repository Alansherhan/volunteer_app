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
      final response = await http.post(
        Uri.parse('$kBaseUrl/public/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'role': role}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await prefs.setString(kTokenStorageKey, data['token'] ?? '');

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

        String? userRole;
        if (data['role'] != null) {
          userRole = data['role'].toString();
          await prefs.setString('role', userRole);
          if (userRole == 'volunteer') {
            return;
          }
        }

        await prefs.setString(kTokenStorageKey, data['token'] ?? '');
        await prefs.setString('email', email);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          _showErrorDialog(error['message'] ?? 'Login failed');
        } catch (e) {
          _showErrorDialog('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      _showErrorDialog('Network error: Please check your connection');
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Reset Password',
            style: AppTheme.mainFont(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address and we\'ll send you instructions to reset your password.',
                style: AppTheme.mainFont(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTheme.mainFont(),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  hintText: 'Email',
                  labelText: 'Email',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTheme.mainFont(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final resetEmail = emailController.text.trim();

                      if (resetEmail.isEmpty) {
                        _showErrorDialog('Please enter your email address');
                        return;
                      }

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
                        final response = await http.post(
                          Uri.parse('$kBaseUrl/public/forgot-password'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'email': resetEmail}),
                        );

                        if (mounted) {
                          Navigator.of(context).pop();
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
                          Navigator.of(context).pop();
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
                  : const Text('Send Reset Link'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: AppTheme.mainFont(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTheme.mainFont(color: AppTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Success',
              style: AppTheme.mainFont(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTheme.mainFont(color: AppTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
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
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/images/logo5.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Welcome Back',
                    style: AppTheme.mainFont(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue making a difference',
                    style: AppTheme.mainFont(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          onChanged: (value) => setState(() => email = value),
                          keyboardType: TextInputType.emailAddress,
                          style: AppTheme.mainFont(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          onChanged: (value) =>
                              setState(() => password = value),
                          obscureText: _obscurePassword,
                          style: AppTheme.mainFont(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _onForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: AppTheme.mainFont(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
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
                                : Text(
                                    'Sign In',
                                    style: AppTheme.mainFont(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTheme.mainFont(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: AppTheme.mainFont(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
