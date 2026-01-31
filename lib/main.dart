import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:volunteer_app/firebase_options.dart';
import 'package:volunteer_app/screens/splash_screen.dart';
import 'package:volunteer_app/services/fcm_service.dart';
import 'package:volunteer_app/services/notification_router.dart';
import 'package:volunteer_app/theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Set up notification router with global navigator key
  NotificationRouter().navigatorKey = navigatorKey;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM after app starts
    _initFcm();
  }

  Future<void> _initFcm() async {
    await FcmService().initialize();

    // Handle any pending notification navigation (from terminated state)
    // This is called after a delay to ensure the app is fully initialized
    // and user has passed the splash screen/login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait for splash screen to complete before handling pending navigation
      Future.delayed(const Duration(seconds: 3), () {
        NotificationRouter().handlePendingNavigation();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Volunteer App',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
