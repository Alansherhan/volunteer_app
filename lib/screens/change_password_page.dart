import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/env.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  String currentPassword = '';
  String newPassword = '';
  String confirmPassword = '';
  bool _isLoading = false;

  Future<void> _changePassword() async {
    // 1. Validation
    if (currentPassword.trim().isEmpty ||
        newPassword.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      _showSnackBar("Please fill in all fields", isError: true);
      return;
    }

    if (newPassword.trim() != confirmPassword.trim()) {
      _showSnackBar("New passwords do not match", isError: true);
      return;
    }

    // if (newPassword.trim().length < 6) {
    //   _showSnackBar("Password must be at least 6 characters", isError: true);
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Get Token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(kTokenStorageKey);

      if (token == null) {
        _showSnackBar("User not authenticated", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // 3. Call API - Check if endpoint is correct
      final response = await http.put(
        Uri.parse('$kBaseUrl/public/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'oldPassword': currentPassword.trim(),
          'newPassword': newPassword.trim(),
        }),
      );

      print("Status: ${response.statusCode}");
      print("Response Headers: ${response.headers}");
      print("Body: ${response.body}");

      // 4. Handle Response with better error checking
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse JSON, but handle if it's not JSON
        try {
          final data = jsonDecode(response.body);
          _showSnackBar(data['message'] ?? "Password updated successfully!");
        } catch (e) {
          _showSnackBar("Password updated successfully!");
        }
        Navigator.pop(context);
      } else {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          _showSnackBar(
            "Server error (${response.statusCode}). Please check the API endpoint.",
            isError: true,
          );
        } else {
          // Try to parse JSON error message
          try {
            final data = jsonDecode(response.body);
            _showSnackBar(
              data['message'] ?? data['error'] ?? "Failed to update password",
              isError: true,
            );
          } catch (e) {
            _showSnackBar(
              "Error ${response.statusCode}: ${response.body}",
              isError: true,
            );
          }
        }
      }
    } on FormatException catch (e) {
      print("FormatException: $e");
      _showSnackBar(
        "Invalid response from server. Please check API endpoint.",
        isError: true,
      );
    } catch (e) {
      print("Error: $e");
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.blue[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            PasswordField(
              hintText: "Enter Current Password",
              onChanged: (value) {
                setState(() {
                  currentPassword = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'New Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            PasswordField(
              hintText: "Enter New Password",
              onChanged: (value) {
                setState(() {
                  newPassword = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirm Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            PasswordField(
              hintText: "Confirm Password",
              onChanged: (value) {
                setState(() {
                  confirmPassword = value;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Password',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, this.onChanged, this.hintText});
  final void Function(String)? onChanged;
  final String? hintText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool isObscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isObscure,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              isObscure = !isObscure;
            });
          },
          icon: Icon(isObscure ? Icons.visibility_off : Icons.remove_red_eye),
        ),
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}
