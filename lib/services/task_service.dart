import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/models/task_model.dart';

class TaskService {
  // Base URL for the API
  static String get baseUrl => '$kBaseUrl/public';

  /// Get auth token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kTokenStorageKey);
    developer.log(
      'Token retrieved: ${token != null ? "exists" : "null"}',
      name: 'TaskService',
    );
    return token;
  }

  /// Fetches all tasks assigned to the logged-in volunteer
  static Future<List<TaskModel>> getMyTasks({String? status}) async {
    try {
      developer.log('Fetching tasks...', name: 'TaskService');

      final token = await _getToken();
      if (token == null) {
        developer.log('ERROR: No token found', name: 'TaskService');
        throw Exception('Not authenticated');
      }

      String url = '$baseUrl/tasks';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }
      developer.log('Requesting: $url', name: 'TaskService');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Response status: ${response.statusCode}',
        name: 'TaskService',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> taskList = data['data'];
          developer.log('Parsed ${taskList.length} tasks', name: 'TaskService');
          return taskList.map((item) => TaskModel.fromJson(item)).toList();
        }
        developer.log(
          'Response success=false or data=null',
          name: 'TaskService',
        );
        return [];
      } else {
        developer.log(
          'ERROR: Status ${response.statusCode}',
          name: 'TaskService',
        );
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log(
        'ERROR: $e',
        name: 'TaskService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Error fetching tasks: $e');
    }
  }

  /// Gets task counts by status
  static Future<Map<String, int>> getTaskCounts() async {
    try {
      final tasks = await getMyTasks();
      return {
        'pending': tasks.where((t) => t.status == 'pending').length,
        'accepted': tasks.where((t) => t.status == 'accepted').length,
        'completed': tasks.where((t) => t.status == 'completed').length,
        'rejected': tasks.where((t) => t.status == 'rejected').length,
        'total': tasks.length,
      };
    } catch (e) {
      developer.log('ERROR getting task counts: $e', name: 'TaskService');
      return {
        'pending': 0,
        'accepted': 0,
        'completed': 0,
        'rejected': 0,
        'total': 0,
      };
    }
  }

  /// Update task status (accept, reject, complete)
  static Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      developer.log('Updating task $taskId to $status', name: 'TaskService');

      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      developer.log(
        'Update status response: ${response.statusCode}',
        name: 'TaskService',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR updating task status: $e',
        name: 'TaskService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
