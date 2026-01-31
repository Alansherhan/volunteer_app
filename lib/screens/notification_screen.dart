import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:volunteer_app/models/notification_model.dart';
import 'package:volunteer_app/models/notification_payload.dart';
import 'package:volunteer_app/services/notification_router.dart';
import 'package:volunteer_app/services/notification_service.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notificationsFuture = NotificationService.getNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _loadNotifications();
    });
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    developer.log(
      'Tapped notification: id=${notification.id}, type=${notification.type}, title=${notification.title}, taskId=${notification.taskId}, data=${notification.data}',
      name: 'NotificationScreen',
    );

    // Mark as read first
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
      _refreshNotifications();
    }

    // Navigate to detail screen based on notification type
    final payload = _createPayloadFromNotification(notification);

    // Use context-based navigation with source = notificationScreen
    // This tells the router we're already on the notification screen
    // and prevents stacking multiple notification screens
    if (mounted) {
      final result = await NotificationRouter()
          .handleNotificationTapWithContext(
            context,
            payload,
            source: NavigationSource.notificationScreen,
          );

      developer.log(
        'Notification tap result: $result',
        name: 'NotificationScreen',
      );

      // Handle different results with appropriate feedback
      if (result == NotificationTapResult.failed && mounted) {
        developer.log(
          'Showing snackbar for failed result',
          name: 'NotificationScreen',
        );
        // Show error feedback when task/detail couldn't be loaded
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This ${notification.type.startsWith('task_') ? 'task' : 'item'} is no longer available',
                    style: AppTheme.mainFont(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // noAction is expected for broadcast notifications - no feedback needed
    }
  }

  NotificationPayload _createPayloadFromNotification(
    NotificationModel notification,
  ) {
    // Build data map from notification
    final Map<String, dynamic> data = {
      'type': notification.type,
      'notificationId': notification.id,
    };

    // Add task ID - check direct field first, then data map
    if (notification.taskId != null) {
      data['taskId'] = notification.taskId;
      developer.log(
        'TaskId from notification.taskId: ${notification.taskId}',
        name: 'NotificationScreen',
      );
    } else if (notification.data != null &&
        notification.data!['taskId'] != null) {
      data['taskId'] = notification.data!['taskId'];
      developer.log(
        'TaskId from notification.data: ${notification.data!['taskId']}',
        name: 'NotificationScreen',
      );
    } else {
      developer.log(
        'No taskId found in notification: ${notification.id}, type: ${notification.type}, data: ${notification.data}',
        name: 'NotificationScreen',
      );
    }

    developer.log(
      'Created payload for notification ${notification.id}: $data',
      name: 'NotificationScreen',
    );

    return NotificationPayload.fromMap(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Notifications',
                      style: AppTheme.mainFont(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  color: AppTheme.primaryColor,
                  child: FutureBuilder<List<NotificationModel>>(
                    future: _notificationsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading notifications...',
                                style: AppTheme.mainFont(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState(snapshot.error.toString());
                      }

                      final notifications = snapshot.data ?? [];

                      if (notifications.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(notifications[index]);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final bool isTaskNotification = notification.type.startsWith('task_');
    final bool canNavigateToDetail =
        isTaskNotification && notification.taskId != null;

    Color accentColor;
    IconData iconData;

    // Determine accent color and icon based on notification type
    switch (notification.type) {
      case 'task_assigned':
        accentColor = AppTheme.warningColor;
        iconData = Icons.assignment_rounded;
        break;
      case 'task_accepted':
        accentColor = AppTheme.primaryColor;
        iconData = Icons.check_circle_rounded;
        break;
      case 'task_completed':
        accentColor = Colors.green;
        iconData = Icons.task_alt_rounded;
        break;
      case 'task_rejected':
        accentColor = AppTheme.errorColor;
        iconData = Icons.cancel_rounded;
        break;
      case 'task_status_updated':
        accentColor = Colors.blue;
        iconData = Icons.update_rounded;
        break;
      case 'admin_broadcast':
        accentColor = Colors.purple;
        iconData = Icons.campaign_rounded;
        break;
      default:
        accentColor = AppTheme.primaryColor;
        iconData = Icons.notifications_rounded;
    }

    return GestureDetector(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppTheme.surfaceColor
              : AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: notification.isRead
              ? null
              : Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            notification.typeLabel,
                            style: AppTheme.mainFont(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notification.timeAgo,
                          style: AppTheme.mainFont(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      notification.title,
                      style: AppTheme.mainFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTheme.mainFont(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show "View details" hint for navigable notifications
                    if (canNavigateToDetail) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Tap to view details',
                            style: AppTheme.mainFont(
                              fontSize: 11,
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: AppTheme.mainFont(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! 🎉',
            style: AppTheme.mainFont(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTheme.mainFont(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to try again',
              style: AppTheme.mainFont(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshNotifications,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
