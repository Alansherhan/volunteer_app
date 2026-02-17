import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/auth/volunteer_login.dart';
import 'package:volunteer_app/auth/widgets/auth_text_field.dart';
import 'package:volunteer_app/auth/widgets/auth_button.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/theme/app_theme.dart';
import 'package:volunteer_app/widgets/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String phoneNo = '';
  String address = '';
  String role = 'volunteer';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
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
                    const SizedBox(height: 24),
                    Text(
                      'Create Account',
                      style: AppTheme.mainFont(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Making a difference, Together',
                      style: AppTheme.mainFont(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            prefixIcon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            onChanged: (value) => setState(() => name = value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name is required';
                              }
                              if (value.length < 3) {
                                return 'Name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          AuthTextField(
                            label: 'Email Address',
                            hint: 'Enter your email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onChanged: (value) => setState(() => email = value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          AuthTextField(
                            label: 'Password',
                            hint: 'Enter password',
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            textInputAction: TextInputAction.next,
                            onChanged: (value) =>
                                setState(() => password = value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          AuthTextField(
                            label: 'Confirm Password',
                            hint: 'Re-enter password',
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            textInputAction: TextInputAction.next,
                            onChanged: (value) =>
                                setState(() => confirmPassword = value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != password) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          AuthTextField(
                            label: 'Phone Number',
                            hint: '+91 1234567890',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            onChanged: (value) =>
                                setState(() => phoneNo = value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone number is required';
                              }
                              final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
                              if (!phoneRegex.hasMatch(
                                value.replaceAll(' ', ''),
                              )) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          AuthTextField(
                            label: 'Address',
                            hint: 'Enter your full address',
                            prefixIcon: Icons.location_on_outlined,
                            keyboardType: TextInputType.streetAddress,
                            textInputAction: TextInputAction.done,
                            onChanged: (value) =>
                                setState(() => address = value),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Address is required';
                              }
                              if (value.length < 5) {
                                return 'Please enter a complete address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          AuthButton(
                            text: 'SIGN UP',
                            isLoading: _isLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _onSignUpPressed(
                                  name,
                                  email,
                                  password,
                                  phoneNo,
                                  address,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: AppTheme.mainFont(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Log In",
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
      ),
    );
  }

  Future<void> _onSignUpPressed(
    String name,
    String email,
    String password,
    String phoneNumber,
    String address,
  ) async {
    setState(() {
      _isLoading = true;
    });

    const loginRoute = '$kBaseUrl/public/signup';

    log('Attempting to connect to: $loginRoute');

    final cleanUrl = loginRoute.trim();

    var body = jsonEncode({
      "name": name,
      "email": email,
      "role": role,
      "password": password,
      "phoneNumber": phoneNumber,
      "address": address,
    });

    try {
      final response = await http.post(
        Uri.parse(cleanUrl),
        headers: {"Accept": "*/*", "Content-Type": "application/json"},
        body: body,
      );

      log(response.body);

      if (response.statusCode == 201) {
        log('ssss');
        final parsedBody = jsonDecode(response.body) as Map<String, dynamic>;

        log(parsedBody.toString());

        final token = parsedBody['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kTokenStorageKey, token);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
            (r) => false,
          );
        }
      } else {
        log(response.body);
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? "Sign up failed");
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      _showError("Something went wrong: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
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
}
