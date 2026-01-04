class TaskModel {
  final String id;
  final String taskName;
  final String taskType; // "aid" | "donation"
  final String
  status; // "open" | "assigned" | "accepted" | "completed" | "rejected"
  final String priority; // "high" | "medium" | "low"
  final String? imageUrl;
  final DateTime? createdAt;
  final Map<String, dynamic>? aidRequest;
  final Map<String, dynamic>? donationRequest;

  TaskModel({
    required this.id,
    required this.taskName,
    required this.taskType,
    required this.status,
    required this.priority,
    this.imageUrl,
    this.createdAt,
    this.aidRequest,
    this.donationRequest,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'] ?? json['id'] ?? '',
      taskName: json['taskName'] ?? '',
      taskType: json['taskType'] ?? 'aid',
      status: json['status'] ?? 'assigned',
      priority: json['priority'] ?? 'low',
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      aidRequest: json['aidRequest'] is Map<String, dynamic>
          ? json['aidRequest']
          : null,
      donationRequest: json['donationRequest'] is Map<String, dynamic>
          ? json['donationRequest']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskName': taskName,
      'taskType': taskType,
      'status': status,
      'priority': priority,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'aidRequest': aidRequest,
      'donationRequest': donationRequest,
    };
  }

  /// Returns a user-friendly task type label
  String get taskTypeLabel {
    switch (taskType) {
      case 'aid':
        return 'Aid Request';
      case 'donation':
        return 'Donation';
      default:
        return taskType;
    }
  }

  /// Returns a user-friendly priority label with color hint
  String get priorityLabel {
    switch (priority) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return priority;
    }
  }

  /// Returns a relative time string
  String get timeAgo {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

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

  /// Get location from aid or donation request
  String? get location {
    if (aidRequest != null && aidRequest!['location'] != null) {
      return aidRequest!['location'];
    }
    if (donationRequest != null && donationRequest!['location'] != null) {
      return donationRequest!['location'];
    }
    return null;
  }
}
