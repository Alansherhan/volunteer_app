import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volunteer_app/models/notification_model.dart';
import 'package:volunteer_app/models/notification_payload.dart';
import 'package:volunteer_app/services/notification_router.dart';
import 'package:volunteer_app/theme/app_theme.dart';

/// Bottom sheet to display full notification details
/// Used for notifications that don't navigate to a specific screen
/// (alerts, broadcasts, system notifications, etc.)
class NotificationDetailBottomSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailBottomSheet({super.key, required this.notification});

  /// Show the bottom sheet
  static Future<void> show(
    BuildContext context,
    NotificationModel notification,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          NotificationDetailBottomSheet(notification: notification),
    );
  }

  // Helper getters for task info from notification data
  String? get _taskId =>
      notification.taskId ?? notification.data?['taskId'] as String?;
  String? get _taskTitle => notification.data?['taskTitle'] as String?;
  String? get _taskType => notification.data?['taskType'] as String?;
  String? get _taskLocation => notification.data?['location'] as String?;
  String? get _taskPriority => notification.data?['priority'] as String?;

  bool get _hasTaskInfo => _taskId != null;
  bool get _canViewTask => _taskId != null;

  @override
  Widget build(BuildContext context) {
    final type = parseNotificationType(notification.type);
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);

    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Scrollable content area
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon and type
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Icon container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 32),
                        ),
                        const SizedBox(height: 16),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            notification.typeLabel,
                            style: AppTheme.mainFont(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          notification.title,
                          style: AppTheme.mainFont(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Body
                        Text(
                          notification.body,
                          style: AppTheme.mainFont(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.timeAgo,
                              style: AppTheme.mainFont(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Task info section (if available)
                  if (_hasTaskInfo) ...[
                    Divider(height: 1, color: Colors.grey[200]),
                    _buildTaskInfoSection(context, color),
                  ],
                ],
              ),
            ),
          ),
          // Divider
          Divider(height: 1, color: Colors.grey[200]),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // View Task button (if we have task ID)
                if (_canViewTask) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _viewTask(context),
                      icon: const Icon(Icons.assignment, size: 18),
                      label: Text(
                        'View Task',
                        style: AppTheme.mainFont(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Dismiss button as secondary
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Dismiss',
                        style: AppTheme.mainFont(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Just the "Got it" button if no task to view
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Got it',
                        style: AppTheme.mainFont(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Extra padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Build the task information section
  Widget _buildTaskInfoSection(BuildContext context, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(Icons.assignment, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Task Details',
                style: AppTheme.mainFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Task card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                // Task title
                if (_taskTitle != null)
                  _buildInfoRow(
                    icon: Icons.title,
                    label: 'Task',
                    value: _taskTitle!,
                  ),
                // Task type
                if (_taskType != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.category,
                    label: 'Type',
                    value: _formatTaskType(_taskType!),
                  ),
                ],
                // Task location
                if (_taskLocation != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: _taskLocation!,
                  ),
                ],
                // Task priority
                if (_taskPriority != null) ...[
                  const SizedBox(height: 8),
                  _buildPriorityRow(_taskPriority!),
                ],
                // Task ID (for reference)
                if (_taskId != null) ...[
                  const SizedBox(height: 12),
                  _buildTaskIdRow(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTheme.mainFont(fontSize: 13, color: AppTheme.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.mainFont(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityRow(String priority) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = AppTheme.errorColor;
        break;
      case 'medium':
        priorityColor = AppTheme.warningColor;
        break;
      default:
        priorityColor = AppTheme.successColor;
    }

    return Row(
      children: [
        Icon(Icons.flag, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          'Priority: ',
          style: AppTheme.mainFont(fontSize: 13, color: AppTheme.textMuted),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            priority.toUpperCase(),
            style: AppTheme.mainFont(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: priorityColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskIdRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.tag, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          'ID: ',
          style: AppTheme.mainFont(fontSize: 13, color: AppTheme.textMuted),
        ),
        Expanded(
          child: Text(
            _taskId!.length > 12 ? '${_taskId!.substring(0, 12)}...' : _taskId!,
            style: AppTheme.mainFont(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
        // Copy button
        SizedBox(
          height: 28,
          width: 28,
          child: IconButton(
            onPressed: () => _copyToClipboard(context, _taskId!),
            icon: const Icon(Icons.copy, size: 14),
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              padding: EdgeInsets.zero,
            ),
            tooltip: 'Copy task ID',
          ),
        ),
      ],
    );
  }

  String _formatTaskType(String taskType) {
    // Convert task type code to display name
    switch (taskType.toLowerCase()) {
      case 'aid_delivery':
        return 'Aid Delivery';
      case 'medical_assistance':
        return 'Medical Assistance';
      case 'rescue':
        return 'Rescue Operation';
      case 'logistics':
        return 'Logistics Support';
      case 'shelter':
        return 'Shelter Management';
      default:
        return taskType
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) {
              if (word.isEmpty) return word;
              return word[0].toUpperCase() + word.substring(1);
            })
            .join(' ');
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Task ID copied to clipboard',
          style: AppTheme.mainFont(color: Colors.white),
        ),
        backgroundColor: AppTheme.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Navigate to view the task
  void _viewTask(BuildContext context) async {
    developer.log(
      'View Task pressed - taskId: $_taskId, notificationId: ${notification.id}, type: ${notification.type}',
      name: 'NotificationDetailBottomSheet',
    );

    if (_taskId == null || _taskId!.isEmpty) {
      developer.log(
        'No taskId available!',
        name: 'NotificationDetailBottomSheet',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task ID not available',
            style: AppTheme.mainFont(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Create payload from notification model (like the public app)
    final payload = NotificationPayload.fromNotificationModel(notification);

    developer.log(
      'Payload created - taskId: ${payload.taskId}, type: ${payload.type}',
      name: 'NotificationDetailBottomSheet',
    );

    // Close loading dialog
    Navigator.of(context).pop();

    // Close the bottom sheet
    Navigator.of(context).pop();

    // Use the router with global navigator key (context is invalid after pop)
    final result = await NotificationRouter().handleNotificationTap(payload);

    developer.log(
      'Navigation result: $result',
      name: 'NotificationDetailBottomSheet',
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      // Task notification colors
      case NotificationType.taskAssigned:
        return AppTheme.warningColor;
      case NotificationType.taskAccepted:
        return AppTheme.primaryColor;
      case NotificationType.taskStatusUpdated:
        return Colors.blue;
      case NotificationType.taskCompleted:
        return AppTheme.successColor;
      case NotificationType.taskRejected:
        return AppTheme.errorColor;
      case NotificationType.taskOpenBroadcast:
        return AppTheme.primaryColor; // New task available
      // Broadcast/system colors
      case NotificationType.adminBroadcast:
        return Colors.purple;
      case NotificationType.systemNotification:
        return Colors.blueGrey;
      case NotificationType.unknown:
        return AppTheme.textMuted;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      // Task notification icons
      case NotificationType.taskAssigned:
        return Icons.assignment_ind;
      case NotificationType.taskAccepted:
        return Icons.check_circle;
      case NotificationType.taskStatusUpdated:
        return Icons.update;
      case NotificationType.taskCompleted:
        return Icons.task_alt;
      case NotificationType.taskRejected:
        return Icons.cancel;
      case NotificationType.taskOpenBroadcast:
        return Icons.local_shipping; // Pickup/delivery task icon
      // Broadcast/system icons
      case NotificationType.adminBroadcast:
        return Icons.campaign;
      case NotificationType.systemNotification:
        return Icons.info_outline;
      case NotificationType.unknown:
        return Icons.notifications;
    }
  }
}
