/// Enum representing all supported notification types for volunteer app
enum NotificationType {
  // Task notifications
  taskAssigned,
  taskAccepted,
  taskStatusUpdated,
  taskCompleted,
  taskRejected,

  // Admin notifications
  adminBroadcast,

  // System notifications
  systemNotification,

  // Unknown/fallback
  unknown,
}

/// Extension to convert string type to enum
extension NotificationTypeExtension on NotificationType {
  /// Convert notification type to backend string format
  String toBackendString() {
    switch (this) {
      case NotificationType.taskAssigned:
        return 'task_assigned';
      case NotificationType.taskAccepted:
        return 'task_accepted';
      case NotificationType.taskStatusUpdated:
        return 'task_status_updated';
      case NotificationType.taskCompleted:
        return 'task_completed';
      case NotificationType.taskRejected:
        return 'task_rejected';
      case NotificationType.adminBroadcast:
        return 'admin_broadcast';
      case NotificationType.systemNotification:
        return 'system_notification';
      case NotificationType.unknown:
        return 'unknown';
    }
  }

  /// Check if this notification type relates to tasks
  bool get isTaskNotification {
    return this == NotificationType.taskAssigned ||
        this == NotificationType.taskAccepted ||
        this == NotificationType.taskStatusUpdated ||
        this == NotificationType.taskCompleted ||
        this == NotificationType.taskRejected;
  }

  /// Check if this notification type is a broadcast
  bool get isBroadcast {
    return this == NotificationType.adminBroadcast;
  }
}

/// Parse backend notification type string to enum
NotificationType parseNotificationType(String? type) {
  switch (type) {
    case 'task_assigned':
      return NotificationType.taskAssigned;
    case 'task_accepted':
      return NotificationType.taskAccepted;
    case 'task_status_updated':
      return NotificationType.taskStatusUpdated;
    case 'task_completed':
      return NotificationType.taskCompleted;
    case 'task_rejected':
      return NotificationType.taskRejected;
    case 'admin_broadcast':
      return NotificationType.adminBroadcast;
    case 'system_notification':
      return NotificationType.systemNotification;
    default:
      return NotificationType.unknown;
  }
}

/// Model representing a notification payload from FCM
class NotificationPayload {
  /// The type of notification
  final NotificationType type;

  /// The notification ID from backend (for marking as read)
  final String? notificationId;

  /// Task ID (for task notifications)
  final String? taskId;

  /// Raw data map for any additional fields
  final Map<String, dynamic> rawData;

  NotificationPayload({
    required this.type,
    this.notificationId,
    this.taskId,
    this.rawData = const {},
  });

  /// Create a payload from FCM data map
  factory NotificationPayload.fromMap(Map<String, dynamic> data) {
    return NotificationPayload(
      type: parseNotificationType(data['type'] as String?),
      notificationId: data['notificationId'] as String?,
      taskId: data['taskId'] as String?,
      rawData: data,
    );
  }

  /// Create a payload from NotificationModel (for notification screen taps)
  factory NotificationPayload.fromNotificationModel(dynamic notification) {
    final Map<String, dynamic> data = {};

    // Get the type
    final String typeStr = notification.type as String? ?? 'unknown';

    // Get the data map from notification if available
    if (notification.data != null && notification.data is Map) {
      data.addAll(Map<String, dynamic>.from(notification.data));
    }

    // Add type and notificationId
    data['type'] = typeStr;
    data['notificationId'] = notification.id;

    return NotificationPayload.fromMap(data);
  }

  /// Convert payload to map (for storage/serialization)
  Map<String, dynamic> toMap() {
    return {
      'type': type.toBackendString(),
      if (notificationId != null) 'notificationId': notificationId,
      if (taskId != null) 'taskId': taskId,
      ...rawData,
    };
  }

  /// Check if this payload has enough data to navigate to task detail
  bool get canNavigateToTask {
    return type.isTaskNotification && taskId != null && taskId!.isNotEmpty;
  }

  @override
  String toString() {
    return 'NotificationPayload(type: $type, taskId: $taskId, notificationId: $notificationId)';
  }
}
