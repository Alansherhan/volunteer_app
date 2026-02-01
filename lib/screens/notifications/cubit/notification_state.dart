part of 'notification_cubit.dart';

/// Base state for notifications
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class NotificationInitial extends NotificationState {}

/// Loading state while fetching notifications
class NotificationLoading extends NotificationState {}

/// State when notifications are successfully loaded
class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

/// Error state when something goes wrong
class NotificationError extends NotificationState {
  final String message;
  final int statusCode;

  const NotificationError({required this.message, this.statusCode = 500});

  @override
  List<Object?> get props => [message, statusCode];
}
