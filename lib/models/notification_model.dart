class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? recipientId;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final String? taskId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.recipientId,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
    this.taskId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      recipientId: json['recipientId'],
      type: json['type'] ?? 'admin_broadcast',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      taskId: json['taskId'] ?? json['data']?['taskId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'recipientId': recipientId,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (data != null) 'data': data,
      if (taskId != null) 'taskId': taskId,
    };
  }

  /// Returns the notification type as a user-friendly string
  String get typeLabel {
    switch (type) {
      case 'task_assigned':
        return 'Task Assignment';
      case 'admin_broadcast':
        return 'Announcement';
      default:
        return 'Notification';
    }
  }

  /// Returns a relative time string (e.g., "2 hours ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
