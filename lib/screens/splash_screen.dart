import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/auth/volunteer_login.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/widgets/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // check if we have token
    _checkToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Future<void> _checkToken() async {
    // Add a small delay for splash screen visibility (optional)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(
      "$kTokenStorageKey",
    ); // or use kTokenStorageKey if defined in Env

    print('Token: $token'); // Add this
    print('Mounted: $mounted'); // Add this

    if (token == null || token.isEmpty) {
      // navigate to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
          (r) => false,
        );
      }
    } else {
      // navigate to home screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (r) => false,
        );
      }
    }
  }
}
