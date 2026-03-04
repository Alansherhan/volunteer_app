import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/auth/volunteer_login.dart';

/// Centralized authentication service with mutex protection against multiple redirects.
///
/// Use this service to handle 401 Unauthorized errors consistently across the app.
/// The singleton pattern ensures only one instance exists, and the mutex flag
/// prevents race conditions when multiple API calls return 401 simultaneously.
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Mutex flag to prevent multiple concurrent logout attempts.
  bool _isLoggingOut = false;

  /// Returns true if a logout/redirect is currently in progress.
  bool get isLoggingOut => _isLoggingOut;

  /// Handles 401 Unauthorized errors by clearing the token and redirecting to login.
  ///
  /// This method is idempotent - calling it multiple times while a logout is
  /// already in progress will have no effect (thanks to the mutex flag).
  Future<void> handleUnauthorized(
    BuildContext context, {
    String message = 'Session expired. Please login again.',
  }) async {
    // Check if already processing a logout to prevent multiple redirects
    if (_isLoggingOut) {
      debugPrint(
        'AuthService: Already logging out, skipping duplicate request',
      );
      return;
    }

    // Check if context is still valid
    if (!context.mounted) {
      debugPrint('AuthService: Context not mounted, cannot redirect');
      return;
    }

    // Set mutex to prevent concurrent logout attempts
    _isLoggingOut = true;

    try {
      // Clear the stored token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kTokenStorageKey);

      // Double-check context is still mounted after async operation
      if (!context.mounted) {
        debugPrint('AuthService: Context became unmounted during logout');
        return;
      }

      // Show message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to login screen, clearing all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('AuthService: Error during logout: $e');
    } finally {
      // Reset mutex after a short delay to allow navigation to complete
      Future.delayed(const Duration(milliseconds: 500), () {
        _isLoggingOut = false;
      });
    }
  }

  /// Manually logout the user (for explicit logout button actions).
  Future<void> logout(BuildContext context) async {
    if (_isLoggingOut) return;
    if (!context.mounted) return;

    _isLoggingOut = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kTokenStorageKey);

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('AuthService: Error during logout: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isLoggingOut = false;
      });
    }
  }

  /// Resets the logging out state. Use only for testing or recovery scenarios.
  void resetState() {
    _isLoggingOut = false;
  }
}
