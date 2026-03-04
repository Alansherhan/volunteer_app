import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/models/notification_model.dart';

class NotificationService {
  // Base URL for the API
  static String get baseUrl => '$kBaseUrl/public';

  /// Get auth token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kTokenStorageKey);
    developer.log(
      'Token retrieved: ${token != null ? "exists" : "null"}',
      name: 'NotificationService',
    );
    return token;
  }

  /// Fetches all notifications for the logged-in volunteer
  static Future<List<NotificationModel>> getNotifications() async {
    try {
      developer.log('Fetching notifications...', name: 'NotificationService');

      final token = await _getToken();
      if (token == null) {
        developer.log('ERROR: No token found', name: 'NotificationService');
        throw Exception('Not authenticated');
      }

      final url = '$baseUrl/notifications';
      developer.log('Requesting: $url', name: 'NotificationService');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Response status: ${response.statusCode}',
        name: 'NotificationService',
      );
      developer.log(
        'Response body: ${response.body}',
        name: 'NotificationService',
      );

      if (response.statusCode == 401) {
        developer.log('ERROR: Unauthorized (401)', name: 'NotificationService');
        throw Exception('Unauthorized');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> notificationList = data['data'];
          developer.log(
            'Parsed ${notificationList.length} notifications',
            name: 'NotificationService',
          );
          return notificationList
              .map((item) => NotificationModel.fromJson(item))
              .toList();
        }
        developer.log(
          'Response success=false or data=null',
          name: 'NotificationService',
        );
        return [];
      } else {
        developer.log(
          'ERROR: Status ${response.statusCode}',
          name: 'NotificationService',
        );
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log(
        'ERROR: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Marks a notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      developer.log(
        'Marking notification $notificationId as read',
        name: 'NotificationService',
      );

      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Mark as read response: ${response.statusCode}',
        name: 'NotificationService',
      );
      return response.statusCode == 200;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR marking as read: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Marks all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      developer.log(
        'Marking all notifications as read',
        name: 'NotificationService',
      );

      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Mark all as read response: ${response.statusCode}',
        name: 'NotificationService',
      );
      return response.statusCode == 200;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR marking all as read: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Gets the count of unread notifications
  static Future<int> getUnreadCount() async {
    try {
      developer.log('Getting unread count...', name: 'NotificationService');
      final notifications = await getNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      developer.log(
        'Unread count: $unreadCount (total: ${notifications.length})',
        name: 'NotificationService',
      );
      return unreadCount;
    } catch (e) {
      developer.log(
        'ERROR getting unread count: $e',
        name: 'NotificationService',
      );
      return 0;
    }
  }
}
