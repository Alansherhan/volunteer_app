import 'dart:convert';

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
  String password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _onLoginPressed(String email, String password) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both email and password');
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
        body: jsonEncode({'email': email, 'password': password}),
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

        // Save alternate token key for Edit Profile compatibility
        await prefs.setString('auth_token', data['token'] ?? '');
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
      body: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 231, 228, 228),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 100,
                      height: 100,
                      child: Image(
                        image: AssetImage('assets/images/logo3.png'),
                      ),
                    ),
                    const Text(
                      'Volunteer',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Companion App',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Making a difference, Together',
                      style: TextStyle(fontSize: 16.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          email = value;
                        });
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 225, 223, 223),
                          ),
                        ),
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintText: "Email",
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        prefixIcon: const Icon(Icons.key),
                        hintText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: TextButton(
                    //     onPressed: _onForgotPassword,
                    //     child: const Text(
                    //       'Forgot Password?',
                    //       style: TextStyle(
                    //         color: Color.fromARGB(255, 116, 188, 247),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            116,
                            188,
                            247,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () {
                                _onLoginPressed(email, password);
                              },
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'LOG IN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't you have an account?,"),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text("Sign Up"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
