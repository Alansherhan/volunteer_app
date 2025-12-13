import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:volunteer_app/auth/volunteer_login.dart';
import 'package:volunteer_app/screens/Dashboard.dart';
import 'package:volunteer_app/screens/splash_screen.dart';
import 'package:volunteer_app/widgets/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ADD THIS LINE
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volunteer App',
      theme: _buildTheme(Brightness.light),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final ThemeData baseTheme = ThemeData(brightness: brightness);

    return baseTheme.copyWith(
      textTheme: GoogleFonts.josefinSansTextTheme(baseTheme.textTheme),
    );
  }
}
