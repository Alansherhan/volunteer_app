import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/notification_payload.dart';
import '../models/task_model.dart';
import '../screens/notification_screen.dart';
import '../screens/dashboard_screen/task_screen.dart';
import 'task_service.dart';

/// Navigation context to help make smart navigation decisions
enum NavigationSource {
  /// Notification tap from FCM (system tray)
  fcmTap,

  /// Notification tap from notification screen
  notificationScreen,

  /// Notification tap from elsewhere in the app
  inApp,
}

/// Result of a notification tap action
enum NotificationTapResult {
  /// Successfully navigated to the target screen
  navigated,

  /// Already on the target screen, no navigation needed
  alreadyOnScreen,

  /// No action needed for this notification type
  noAction,

  /// Failed to navigate (e.g., couldn't fetch data)
  failed,
}

/// Service for handling notification tap navigation
///
/// This router centralizes all notification-based navigation logic,
/// making it easy to add new notification types and their handlers.
class NotificationRouter {
  static final NotificationRouter _instance = NotificationRouter._internal();
  factory NotificationRouter() => _instance;
  NotificationRouter._internal();

  /// Global navigator key - must be set from main.dart
  GlobalKey<NavigatorState>? navigatorKey;

  /// Pending payload to handle after app initialization (from terminated state)
  NotificationPayload? _pendingPayload;

  /// Set pending payload (called when app opens from terminated state)
  void setPendingPayload(NotificationPayload payload) {
    _pendingPayload = payload;
    developer.log(
      'Pending notification payload set: $payload',
      name: 'NotificationRouter',
    );
  }

  /// Check and handle pending navigation (call after app is fully initialized)
  Future<void> handlePendingNavigation() async {
    if (_pendingPayload != null) {
      developer.log(
        'Processing pending notification: ${_pendingPayload!.type}',
        name: 'NotificationRouter',
      );
      final payload = _pendingPayload!;
      _pendingPayload = null;

      // Small delay to ensure navigation stack is ready
      await Future.delayed(const Duration(milliseconds: 500));
      await handleNotificationTap(payload);
    }
  }

  /// Handle notification tap - main entry point
  /// Use this when navigating from FCM (uses global navigator)
  Future<NotificationTapResult> handleNotificationTap(
    NotificationPayload payload, {
    NavigationSource source = NavigationSource.fcmTap,
  }) async {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) {
      developer.log(
        'Navigator not available, cannot handle notification tap',
        name: 'NotificationRouter',
      );
      return NotificationTapResult.failed;
    }
    return await _handleNavigation(navigator, payload, source: source);
  }

  /// Handle notification tap with BuildContext - use this from screens
  /// This ensures proper navigation within the current navigation stack
  Future<NotificationTapResult> handleNotificationTapWithContext(
    BuildContext context,
    NotificationPayload payload, {
    NavigationSource source = NavigationSource.inApp,
  }) async {
    final navigator = Navigator.of(context);
    return await _handleNavigation(navigator, payload, source: source);
  }

  /// Internal navigation handler
  Future<NotificationTapResult> _handleNavigation(
    NavigatorState navigator,
    NotificationPayload payload, {
    required NavigationSource source,
  }) async {
    developer.log(
      'Handling notification tap: ${payload.type} from $source',
      name: 'NotificationRouter',
    );

    try {
      switch (payload.type) {
        // Task notifications - navigate to task detail
        case NotificationType.taskAssigned:
        case NotificationType.taskAccepted:
        case NotificationType.taskStatusUpdated:
        case NotificationType.taskCompleted:
        case NotificationType.taskRejected:
          return await _navigateToTaskDetail(navigator, payload, source);

        // Broadcast and other notifications - these don't have a detail screen
        // When tapped from notification screen, just mark as read (no navigation)
        // When tapped from FCM, navigate to notification screen
        case NotificationType.adminBroadcast:
        case NotificationType.systemNotification:
        case NotificationType.unknown:
          if (source == NavigationSource.notificationScreen) {
            // Already on notification screen, no action needed
            developer.log(
              'Broadcast notification tapped from notification screen - no action',
              name: 'NotificationRouter',
            );
            return NotificationTapResult.noAction;
          }
          return _navigateToNotifications(navigator, source);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error handling notification tap: $e',
        name: 'NotificationRouter',
        error: e,
        stackTrace: stackTrace,
      );
      // Only fallback to notifications if not already on notification screen
      if (source != NavigationSource.notificationScreen) {
        _navigateToNotifications(navigator, source);
      }
      return NotificationTapResult.failed;
    }
  }

  /// Navigate to task detail screen
  Future<NotificationTapResult> _navigateToTaskDetail(
    NavigatorState navigator,
    NotificationPayload payload,
    NavigationSource source,
  ) async {
    final taskId = payload.taskId;

    if (taskId == null || taskId.isEmpty) {
      developer.log(
        'No taskId in payload, falling back to notifications',
        name: 'NotificationRouter',
      );
      if (source != NavigationSource.notificationScreen) {
        _navigateToNotifications(navigator, source);
      }
      return NotificationTapResult.failed;
    }

    developer.log('Navigating to task: $taskId', name: 'NotificationRouter');

    // Fetch the task details
    final task = await _fetchTask(taskId);

    if (task != null) {
      // If coming from notification screen, use push
      // If coming from FCM and not on notification screen, also push
      // This ensures proper back navigation
      navigator.push(MaterialPageRoute(builder: (_) => TaskScreen(task: task)));
      return NotificationTapResult.navigated;
    } else {
      developer.log(
        'Failed to fetch task, falling back to notifications',
        name: 'NotificationRouter',
      );
      if (source != NavigationSource.notificationScreen) {
        _navigateToNotifications(navigator, source);
      }
      return NotificationTapResult.failed;
    }
  }

  /// Navigate to notifications screen
  /// Returns the result of the navigation
  NotificationTapResult _navigateToNotifications(
    NavigatorState navigator,
    NavigationSource source,
  ) {
    developer.log(
      'Navigating to notifications screen from $source',
      name: 'NotificationRouter',
    );

    // Check if we're already on notification screen by examining the route
    // We avoid stacking multiple notification screens
    bool isOnNotificationScreen = false;
    navigator.popUntil((route) {
      if (route.settings.name == '/notifications' ||
          (route is MaterialPageRoute &&
              route.builder(navigator.context) is NotificationScreen)) {
        isOnNotificationScreen = true;
      }
      return true; // Don't actually pop anything, just check
    });

    if (isOnNotificationScreen) {
      developer.log(
        'Already on notification screen, skipping navigation',
        name: 'NotificationRouter',
      );
      return NotificationTapResult.alreadyOnScreen;
    }

    navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/notifications'),
        builder: (_) => const NotificationScreen(),
      ),
    );
    return NotificationTapResult.navigated;
  }

  /// Fetch task by ID
  Future<TaskModel?> _fetchTask(String taskId) async {
    try {
      return await TaskService.getTaskById(taskId);
    } catch (e) {
      developer.log('Error fetching task: $e', name: 'NotificationRouter');
      return null;
    }
  }
}
