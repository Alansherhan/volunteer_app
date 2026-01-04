import 'package:flutter/material.dart';
import 'package:volunteer_app/models/task_model.dart';
import 'package:volunteer_app/services/task_service.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class TaskPoolScreen extends StatefulWidget {
  const TaskPoolScreen({super.key});

  @override
  State<TaskPoolScreen> createState() => _TaskPoolScreenState();
}

class _TaskPoolScreenState extends State<TaskPoolScreen> {
  List<TaskModel> _openTasks = [];
  bool _isLoading = true;
  String? _error;
  String? _claimingTaskId;

  @override
  void initState() {
    super.initState();
    _fetchOpenTasks();
  }

  Future<void> _fetchOpenTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await TaskService.getOpenTasks();
      setState(() {
        _openTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load available tasks';
        _isLoading = false;
      });
    }
  }

  Future<void> _claimTask(TaskModel task) async {
    setState(() {
      _claimingTaskId = task.id;
    });

    try {
      final success = await TaskService.claimTask(task.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.taskName}" claimed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the list
        _fetchOpenTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to claim task. It may have been claimed by someone else.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _claimingTaskId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Tasks',
                      style: AppTheme.mainFont(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Claim tasks that need volunteers',
                      style: AppTheme.mainFont(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTheme.mainFont(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchOpenTasks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_openTasks.isEmpty) {
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
                Icons.check_circle_outline,
                size: 56,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Available Tasks',
              style: AppTheme.mainFont(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All tasks have been claimed. Check back later!',
              style: AppTheme.mainFont(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOpenTasks,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        itemCount: _openTasks.length,
        itemBuilder: (context, index) {
          final task = _openTasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final isClaiming = _claimingTaskId == task.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTaskTypeIcon(task.taskType),
                  color: _getPriorityColor(task.priority),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.taskName,
                      style: AppTheme.mainFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.taskTypeLabel,
                      style: AppTheme.mainFont(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: AppTheme.mainFont(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(task.priority),
                  ),
                ),
              ),
            ],
          ),
          if (task.location != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.location!,
                    style: AppTheme.mainFont(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Claim Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isClaiming ? null : () => _claimTask(task),
              icon: isClaiming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(isClaiming ? 'Claiming...' : 'Claim Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTaskTypeIcon(String taskType) {
    switch (taskType) {
      case 'aid':
        return Icons.medical_services_outlined;
      case 'donation':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.assignment_outlined;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return AppTheme.primaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}
