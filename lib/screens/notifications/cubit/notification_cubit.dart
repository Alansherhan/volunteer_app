import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunteer_app/models/notification_model.dart';
import 'package:volunteer_app/services/notification_service.dart';

part 'notification_state.dart';

/// Cubit for managing notification state
class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationInitial());

  /// Load notifications from the API
  Future<void> loadNotifications() async {
    emit(NotificationLoading());
    try {
      final notifications = await NotificationService.getNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      final errorMessage = e.toString();
      final statusCode = errorMessage.contains('Unauthorized') ? 401 : 500;
      emit(NotificationError(message: errorMessage, statusCode: statusCode));
    }
  }

  /// Refresh notifications (pull to refresh)
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Silently refresh notifications without showing loading state
  /// Use this for background refreshes triggered by FCM push notifications
  Future<void> silentRefresh() async {
    try {
      final notifications = await NotificationService.getNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      // Silently fail for background refresh - don't disrupt current state
      // This is intentional: we don't want FCM-triggered refreshes to show errors
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      final success = await NotificationService.markAsRead(notificationId);
      if (success) {
        // Update local state
        final updatedNotifications = currentState.notifications.map((n) {
          if (n.id == notificationId) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              recipientId: n.recipientId,
              type: n.type,
              targetUserType: n.targetUserType,
              isRead: true,
              createdAt: n.createdAt,
              data: n.data,
              taskId: n.taskId,
            );
          }
          return n;
        }).toList();

        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
        emit(
          NotificationLoaded(
            notifications: updatedNotifications,
            unreadCount: unreadCount,
          ),
        );
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      // Check if there are any unread notifications
      final hasUnread = currentState.notifications.any((n) => !n.isRead);
      if (!hasUnread) {
        return; // No unread notifications, nothing to do
      }

      final success = await NotificationService.markAllAsRead();
      if (success) {
        // Update local state - mark all as read
        final updatedNotifications = currentState.notifications.map((n) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            recipientId: n.recipientId,
            type: n.type,
            targetUserType: n.targetUserType,
            isRead: true,
            createdAt: n.createdAt,
            data: n.data,
            taskId: n.taskId,
          );
        }).toList();

        emit(
          NotificationLoaded(
            notifications: updatedNotifications,
            unreadCount: 0,
          ),
        );
      }
    }
  }

  /// Get only the unread count (lightweight check)
  Future<void> updateUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      final currentState = state;
      if (currentState is NotificationLoaded) {
        emit(
          NotificationLoaded(
            notifications: currentState.notifications,
            unreadCount: count,
          ),
        );
      }
    } catch (_) {
      // Silently fail - don't disrupt UI for badge count
    }
  }
}
