import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
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
        'assigned': tasks.where((t) => t.status == 'assigned').length,
        'accepted': tasks.where((t) => t.status == 'accepted').length,
        'completed': tasks.where((t) => t.status == 'completed').length,
        'rejected': tasks.where((t) => t.status == 'rejected').length,
        'total': tasks.length,
      };
    } catch (e) {
      developer.log('ERROR getting task counts: $e', name: 'TaskService');
      return {
        'assigned': 0,
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

  /// Complete task with proof image upload
  static Future<bool> completeTaskWithProof(
    String taskId,
    File imageFile,
  ) async {
    try {
      developer.log(
        'Completing task $taskId with proof image',
        name: 'TaskService',
      );

      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/tasks/$taskId/complete'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Get the file extension for proper filename
      final extension = imageFile.path.split('.').last.toLowerCase();

      developer.log('File extension: $extension', name: 'TaskService');

      // Read file bytes and create multipart file with proper filename
      final bytes = await imageFile.readAsBytes();
      final filename =
          'proofImage_${DateTime.now().millisecondsSinceEpoch}.$extension';

      request.files.add(
        http.MultipartFile.fromBytes('proofImage', bytes, filename: filename),
      );

      developer.log('Sending multipart request...', name: 'TaskService');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      developer.log(
        'Complete with proof response: ${response.statusCode}',
        name: 'TaskService',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }

      developer.log(
        'Complete with proof failed: ${response.body}',
        name: 'TaskService',
      );
      return false;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR completing task with proof: $e',
        name: 'TaskService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get all open (unclaimed) tasks from the marketplace
  static Future<List<TaskModel>> getOpenTasks() async {
    try {
      developer.log('Fetching open tasks...', name: 'TaskService');

      final token = await _getToken();
      if (token == null) {
        developer.log('ERROR: No token found', name: 'TaskService');
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/tasks/open'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Open tasks response status: ${response.statusCode}',
        name: 'TaskService',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> taskList = data['data'];
          developer.log(
            'Parsed ${taskList.length} open tasks',
            name: 'TaskService',
          );
          return taskList.map((item) => TaskModel.fromJson(item)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load open tasks: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log(
        'ERROR: $e',
        name: 'TaskService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Error fetching open tasks: $e');
    }
  }

  /// Claim an open task
  static Future<bool> claimTask(String taskId) async {
    try {
      developer.log('Claiming task $taskId', name: 'TaskService');

      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Claim task response: ${response.statusCode}',
        name: 'TaskService',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR claiming task: $e',
        name: 'TaskService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Fetch a single task by ID
  static Future<TaskModel?> getTaskById(String taskId) async {
    try {
      developer.log('Fetching task by ID: $taskId', name: 'TaskService');

      final token = await _getToken();
      if (token == null) {
        developer.log('ERROR: No token found', name: 'TaskService');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Get task by ID response: ${response.statusCode}',
        name: 'TaskService',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          developer.log('Task fetched successfully', name: 'TaskService');
          return TaskModel.fromJson(data['data']);
        }
      }

      developer.log(
        'Failed to fetch task: ${response.statusCode}',
        name: 'TaskService',
      );
      return null;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR fetching task by ID: $e',
        name: 'TaskService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
