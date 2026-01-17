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

  // Multi-volunteer support
  final int volunteersNeeded;
  final int currentVolunteerCount;
  final int remainingSlots;
  final List<String> assignedVolunteers;

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
    this.volunteersNeeded = 1,
    this.currentVolunteerCount = 0,
    this.remainingSlots = 1,
    this.assignedVolunteers = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Handle assignedVolunteers array - can be list of objects or strings
    List<String> volunteers = [];
    if (json['assignedVolunteers'] != null) {
      final rawVolunteers = json['assignedVolunteers'] as List;
      volunteers = rawVolunteers
          .map((v) {
            if (v is String) return v;
            if (v is Map)
              return v['_id']?.toString() ?? v['id']?.toString() ?? '';
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final volunteersNeeded = json['volunteersNeeded'] ?? 1;
    final currentCount = json['currentVolunteerCount'] ?? volunteers.length;

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
      volunteersNeeded: volunteersNeeded,
      currentVolunteerCount: currentCount,
      remainingSlots:
          json['remainingSlots'] ?? (volunteersNeeded - currentCount),
      assignedVolunteers: volunteers,
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
      'volunteersNeeded': volunteersNeeded,
      'currentVolunteerCount': currentVolunteerCount,
      'remainingSlots': remainingSlots,
      'assignedVolunteers': assignedVolunteers,
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
    dynamic loc;
    if (aidRequest != null && aidRequest!['location'] != null) {
      loc = aidRequest!['location'];
    } else if (donationRequest != null &&
        donationRequest!['location'] != null) {
      loc = donationRequest!['location'];
    }

    if (loc == null) return null;

    // Handle case where location is a Map object
    if (loc is Map<String, dynamic>) {
      // Try to get address string from the location object
      return loc['address']?.toString() ??
          loc['formattedAddress']?.toString() ??
          loc['name']?.toString();
    }

    // Handle case where location is already a string
    if (loc is String) {
      return loc;
    }

    return null;
  }

  /// Check if task has open slots for more volunteers
  bool get hasOpenSlots => remainingSlots > 0;

  /// Returns volunteer slots info string (e.g., "2/3 volunteers")
  String get volunteerSlotsInfo {
    return '$currentVolunteerCount/$volunteersNeeded volunteers';
  }

  /// Returns remaining slots info string (e.g., "1 spot left")
  String get remainingSlotsInfo {
    if (remainingSlots <= 0) return 'Full';
    if (remainingSlots == 1) return '1 spot left';
    return '$remainingSlots spots left';
  }
}
