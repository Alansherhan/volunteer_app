import 'dart:convert';
import 'package:volunteer_app/theme/app_theme.dart';
import 'package:volunteer_app/auth/widgets/auth_text_field.dart';
import 'package:volunteer_app/auth/widgets/auth_button.dart';

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
  String role = '';
  String password = '';
  bool _isLoading = false;

  Future<void> _onLoginPressed(
    String email,
    String password,
    String role,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both email and password');
      return;
    } else if (role == 'public') {
      _showErrorDialog('You are not authorized to login as public');
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

      //log any static test here to check the response
      print(response.statusCode);

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

        // Get role from user object (backend returns user data nested inside 'user')
        String? userRole;
        if (data['user'] != null && data['user']['role'] != null) {
          userRole = data['user']['role'].toString();
        } else if (data['role'] != null) {
          userRole = data['role'].toString();
        }

        // Only allow volunteers to login to this app
        if (userRole != 'volunteer') {
          await prefs.clear();
          _showErrorDialog(
            'Access denied. Only volunteers can login to this app.',
          );
          return;
        }

        await prefs.setString('role', userRole!);

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
          // Check if there are field-specific validation errors
          if (error['errors'] != null &&
              error['errors'] is List &&
              (error['errors'] as List).isNotEmpty) {
            final errors = error['errors'] as List;
            final errorMessages = errors
                .map((e) => '${e['field']}: ${e['message']}')
                .join('\n');
            _showErrorDialog(errorMessages);
          } else {
            _showErrorDialog(error['message'] ?? 'Login failed');
          }
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
                'Enter your email address and we\'ll send you an OTP to reset your password.',
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
                          // Show OTP verification dialog
                          _showOtpVerificationDialog(resetEmail);
                        } else {
                          try {
                            final error = jsonDecode(response.body);
                            _showErrorDialog(
                              error['message'] ?? 'Failed to send OTP',
                            );
                          } catch (e) {
                            _showErrorDialog(
                              'Failed to send OTP. Please try again.',
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
                  : const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOtpVerificationDialog(String email) async {
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Enter OTP',
            style: AppTheme.mainFont(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the 6-digit OTP sent to $email and set your new password.',
                  style: AppTheme.mainFont(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: AppTheme.mainFont(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '------',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  style: AppTheme.mainFont(),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () => setDialogState(
                        () => obscureNewPassword = !obscureNewPassword,
                      ),
                    ),
                    hintText: 'New Password',
                    labelText: 'New Password',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  style: AppTheme.mainFont(),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () => setDialogState(
                        () => obscureConfirmPassword = !obscureConfirmPassword,
                      ),
                    ),
                    hintText: 'Confirm Password',
                    labelText: 'Confirm Password',
                  ),
                ),
              ],
            ),
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
                      final otp = otpController.text.trim();
                      final newPassword = newPasswordController.text;
                      final confirmPassword = confirmPasswordController.text;

                      if (otp.length != 6) {
                        _showErrorDialog('Please enter the 6-digit OTP');
                        return;
                      }

                      if (newPassword.length < 6) {
                        _showErrorDialog(
                          'Password must be at least 6 characters',
                        );
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        _showErrorDialog('Passwords do not match');
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        final response = await http.post(
                          Uri.parse('$kBaseUrl/public/reset-password'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'email': email,
                            'otp': otp,
                            'newPassword': newPassword,
                          }),
                        );

                        if (mounted) {
                          Navigator.of(context).pop();
                        }

                        if (response.statusCode == 200) {
                          _showSuccessDialog(
                            'Password has been reset successfully. Please login with your new password.',
                          );
                        } else {
                          try {
                            final error = jsonDecode(response.body);
                            _showErrorDialog(
                              error['message'] ?? 'Failed to reset password',
                            );
                          } catch (e) {
                            _showErrorDialog(
                              'Failed to reset password. Please try again.',
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
                  : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.mainFont(color: Colors.white)),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.mainFont(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
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
                  const SizedBox(height: 32),
                  Text(
                    'Welcome Back',
                    style: AppTheme.mainFont(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue making a difference',
                    style: AppTheme.mainFont(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AuthTextField(
                          label: 'Email Address',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            setState(() {
                              email = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          onChanged: (value) {
                            setState(() {
                              password = value;
                            });
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _onForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: AppTheme.mainFont(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AuthButton(
                          text: 'LOG IN',
                          isLoading: _isLoading,
                          onPressed: () {
                            if (!_isLoading) {
                              _onLoginPressed(email, password, role);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTheme.mainFont(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: AppTheme.mainFont(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
