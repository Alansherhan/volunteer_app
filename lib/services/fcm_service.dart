import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'Background message received: ${message.notification?.title}',
    name: 'FCM',
  );
}

/// FCM Service for managing push notifications
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    developer.log(
      'FCM permission status: ${settings.authorizationStatus}',
      name: 'FCM',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Initialize local notifications for foreground
      await _initLocalNotifications();

      // Set up message handlers
      _setupMessageHandlers();

      // Get and register token
      await _registerToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        developer.log('FCM token refreshed', name: 'FCM');
        _sendTokenToServer(newToken);
      });
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'relief_notifications',
      'Relief Notifications',
      description: 'Notifications from Volunteer App',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}', name: 'FCM');
    // You can navigate to specific screens based on payload here
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        'Foreground message: ${message.notification?.title}',
        name: 'FCM',
      );
      _showLocalNotification(message);
    });

    // When app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        'App opened from notification: ${message.notification?.title}',
        name: 'FCM',
      );
      // Handle navigation based on message data
    });

    // Check if app was opened from terminated state via notification
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        developer.log(
          'App opened from terminated: ${message.notification?.title}',
          name: 'FCM',
        );
        // Handle navigation
      }
    });
  }

  /// Show local notification when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'relief_notifications',
      'Relief Notifications',
      channelDescription: 'Notifications from Volunteer App',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: json.encode(message.data),
    );
  }

  /// Get FCM token and register with backend
  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        developer.log('FCM Token: $token', name: 'FCM');
        await _sendTokenToServer(token);
      }
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'FCM');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToServer(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(kTokenStorageKey);

      if (authToken == null) {
        developer.log('No auth token, skipping FCM registration', name: 'FCM');
        return;
      }

      final response = await http.post(
        Uri.parse('$kBaseUrl/public/fcm/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'token': fcmToken}),
      );

      if (response.statusCode == 200) {
        developer.log('FCM token registered with server', name: 'FCM');
      } else {
        developer.log(
          'Failed to register FCM token: ${response.statusCode}',
          name: 'FCM',
        );
      }
    } catch (e) {
      developer.log('Error sending FCM token to server: $e', name: 'FCM');
    }
  }

  /// Unregister FCM token (call on logout)
  Future<void> unregisterToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(kTokenStorageKey);

      if (authToken == null) return;

      await http.delete(
        Uri.parse('$kBaseUrl/public/fcm/unregister'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      developer.log('FCM token unregistered', name: 'FCM');
    } catch (e) {
      developer.log('Error unregistering FCM token: $e', name: 'FCM');
    }
  }

  /// Re-register token after login
  Future<void> onUserLogin() async {
    await _registerToken();
  }
}
