import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import '../firebase_options.dart';
import '../models/notification_payload.dart';
import 'notification_router.dart';

/// Background message handler - must be top-level function
/// This is called when the app is in background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // CRITICAL: Ensure Firebase is initialized for background execution
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  developer.log(
    'Background message received: ${message.notification?.title}',
    name: 'FCM',
  );

  // For background messages, Firebase/Android will automatically show the notification
  // if the message contains a 'notification' payload (which our backend sends)
}

/// FCM Service for managing push notifications
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Callback to notify when a new notification arrives
  void Function()? onNotificationReceived;

  /// Callback for navigation when notification is tapped
  void Function(Map<String, dynamic>)? onNotificationTap;

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
      // CRITICAL: Set foreground notification presentation options
      // This tells Firebase how to display notifications when app is in foreground
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true, // Show alert banner
        badge: true, // Update app badge
        sound: true, // Play sound
      );

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

  /// Handle notification tap (from local notification)
  void _onNotificationTap(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}', name: 'FCM');
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        final payload = NotificationPayload.fromMap(data);
        developer.log('Parsed payload: $payload', name: 'FCM');
        NotificationRouter().handleNotificationTap(payload);
      } catch (e) {
        developer.log('Error parsing payload: $e', name: 'FCM');
      }
    }
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
      // Trigger callback to refresh notification state in UI
      onNotificationReceived?.call();
    });

    // When app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        'App opened from notification: ${message.notification?.title}',
        name: 'FCM',
      );
      // Trigger callback to refresh notification state
      onNotificationReceived?.call();
      _handleNavigation(message);
    });

    // Check if app was opened from terminated state via notification
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        developer.log(
          'App opened from terminated: ${message.notification?.title}',
          name: 'FCM',
        );
        _handleTerminatedNavigation(message);
      }
    });
  }

  /// Handle navigation when app is opened from background
  void _handleNavigation(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      final payload = NotificationPayload.fromMap(
        Map<String, dynamic>.from(message.data),
      );
      developer.log('Handling navigation for payload: $payload', name: 'FCM');
      NotificationRouter().handleNotificationTap(payload);
    }
  }

  /// Handle navigation when app is opened from terminated state
  /// This sets a pending payload that will be processed after app initialization
  void _handleTerminatedNavigation(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      final payload = NotificationPayload.fromMap(
        Map<String, dynamic>.from(message.data),
      );
      developer.log(
        'Setting pending navigation for terminated state: $payload',
        name: 'FCM',
      );
      NotificationRouter().setPendingPayload(payload);
    }
  }

  /// Show local notification when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      developer.log('No notification payload in message', name: 'FCM');
      return;
    }

    developer.log(
      'Showing local notification: ${notification.title}',
      name: 'FCM',
    );

    const androidDetails = AndroidNotificationDetails(
      'relief_notifications',
      'Relief Notifications',
      channelDescription: 'Notifications from Volunteer App',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      showWhen: true,
      visibility: NotificationVisibility.public,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        notification.title,
        notification.body,
        notificationDetails,
        payload: json.encode(message.data),
      );
      developer.log('Local notification shown successfully', name: 'FCM');
    } catch (e) {
      developer.log('Error showing local notification: $e', name: 'FCM');
    }
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
