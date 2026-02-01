import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunteer_app/models/notification_model.dart';
import 'package:volunteer_app/screens/notifications/cubit/notification_cubit.dart';
import 'package:volunteer_app/screens/notifications/widgets/notification_detail_bottom_sheet.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if a NotificationCubit is already provided in the widget tree
    try {
      context.read<NotificationCubit>();
      // Cubit exists, use it directly
      return const _NotificationScreenContent();
    } catch (_) {
      // No cubit found, create a new one for standalone navigation (e.g., from FCM tap)
      return BlocProvider(
        create: (_) => NotificationCubit()..loadNotifications(),
        child: const _NotificationScreenContent(),
      );
    }
  }
}

class _NotificationScreenContent extends StatefulWidget {
  const _NotificationScreenContent();

  @override
  State<_NotificationScreenContent> createState() =>
      _NotificationScreenContentState();
}

class _NotificationScreenContentState
    extends State<_NotificationScreenContent> {
  Timer? _refreshTimer;
  // Store reference to cubit to safely access in dispose()
  late final NotificationCubit _notificationCubit;

  @override
  void initState() {
    super.initState();
    // Save reference to cubit before any async operations
    _notificationCubit = context.read<NotificationCubit>();

    // Load notifications when screen opens
    _notificationCubit.loadNotifications();

    // Set up periodic refresh every 30 seconds while on this screen
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _notificationCubit.silentRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    // Mark all notifications as read when leaving the screen
    _notificationCubit.markAllAsRead();
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    await _notificationCubit.refresh();
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    developer.log(
      'Tapped notification: id=${notification.id}, type=${notification.type}, title=${notification.title}, taskId=${notification.taskId}, data=${notification.data}',
      name: 'NotificationScreen',
    );

    // Mark as read first
    if (!notification.isRead) {
      await _notificationCubit.markAsRead(notification.id);
    }

    // Show bottom sheet with notification details
    if (mounted) {
      await NotificationDetailBottomSheet.show(context, notification);
    }
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
                child: BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, state) {
                    if (state is NotificationLoading) {
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

                    if (state is NotificationError) {
                      return _buildErrorState(state.message);
                    }

                    if (state is NotificationLoaded) {
                      if (state.notifications.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshNotifications,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.notifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(
                              state.notifications[index],
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
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
