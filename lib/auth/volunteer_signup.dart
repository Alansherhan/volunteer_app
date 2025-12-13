import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/auth/volunteer_login.dart';
import 'package:volunteer_app/env.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 250, 246, 246),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo3.png',
                            width: 100,
                            height: 100,
                          ),
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Making a diffrence,Together',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                          SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Full Name', style: TextStyle(fontSize: 16)),
                              SizedBox(height: 2),
                              EditField(
                                prefixIcon: Icons.person,
                                hintText: 'Enter your full name',
                                onChanged: (value) {
                                  setState(() {
                                    name = value;
                                  });
                                },
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
                              SizedBox(height: 12),
                              Text('Email', style: TextStyle(fontSize: 16)),
                              SizedBox(height: 2),
                              EditField(
                                prefixIcon: Icons.email_outlined,
                                hintText: 'your.email@example.com',
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (value) {
                                  setState(() {
                                    email = value;
                                  });
                                },
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
                              SizedBox(height: 12),
                              Text('Password', style: TextStyle(fontSize: 16)),
                              SizedBox(height: 2),
                              PasswordField(
                                prefixIcon: Icons.lock,
                                hintText: "Enter password",
                                onChanged: (value) {
                                  setState(() {
                                    password = value;
                                  });
                                },
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
                              SizedBox(height: 12),
                              Text(
                                'Confirm Password',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 2),
                              PasswordField(
                                prefixIcon: Icons.lock,
                                hintText: "Re-enter password",
                                onChanged: (value) {
                                  setState(() {
                                    confirmPassword = value;
                                  });
                                },
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
                              SizedBox(height: 12),
                              Text(
                                'Phone Number',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 2),
                              EditField(
                                prefixIcon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                hintText: "+91 1234567890",
                                onChanged: (value) {
                                  setState(() {
                                    phoneNo = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Phone number is required';
                                  }
                                  final phoneRegex = RegExp(
                                    r'^\+?[0-9]{10,15}$',
                                  );
                                  if (!phoneRegex.hasMatch(
                                    value.replaceAll(' ', ''),
                                  )) {
                                    return 'Enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 12),
                              Text('Address', style: TextStyle(fontSize: 16)),
                              SizedBox(height: 2),
                              EditField(
                                prefixIcon: Icons.location_on_outlined,
                                maxLines: 2,
                                hintText: "Address",
                                onChanged: (value) {
                                  setState(() {
                                    address = value;
                                  });
                                },
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
                            ],
                          ),
                          SizedBox(height: 24),
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
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
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
                              child: Text(
                                'SIGN UP',
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
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Text("Already have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text("Log In"),
                          ),
                        ],
                      ),
                    ),
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
    const loginRoute = '$kBaseUrl/public/signup';

    // Add this debug log to see the actual URL
    log('Attempting to connect to: $loginRoute');

    // Trim any whitespace (temporary fix)
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
        Uri.parse(cleanUrl), // Use cleaned URL
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

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
          (r) => false,
        );
      } else {
        log(response.body);
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? "Sign up failed");
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      _showError("Something went wrong: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.validator,
  });

  final void Function(String)? onChanged;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool isObscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: isObscure,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              isObscure = !isObscure;
            });
          },
          icon: Icon(isObscure ? Icons.visibility_off : Icons.remove_red_eye),
        ),
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey.withAlpha(190)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
      ),
      onChanged: widget.onChanged,
      validator: widget.validator,
    );
  }
}

class EditField extends StatefulWidget {
  const EditField({
    super.key,
    this.onChanged,
    this.hintText,
    this.keyboardType,
    this.prefixIcon,
    this.maxLines,
    this.validator,
  });

  final void Function(String)? onChanged;
  final String? hintText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final int? maxLines;
  final String? Function(String?)? validator;

  @override
  State<EditField> createState() => _EditFieldState();
}

class _EditFieldState extends State<EditField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey.withAlpha(190)),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          gapPadding: BorderSide.strokeAlignCenter,
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: widget.onChanged,
      validator: widget.validator,
    );
  }
}
