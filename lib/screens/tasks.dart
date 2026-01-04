import 'package:flutter/material.dart';
import 'package:volunteer_app/models/task_model.dart';
import 'package:volunteer_app/screens/dashboard_screen/task_screen.dart';
import 'package:volunteer_app/services/task_service.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class Tasks extends StatefulWidget {
  const Tasks({super.key});

  @override
  State<Tasks> createState() => _TasksState();
}

enum TaskStatus { Assigned, Accepted, Completed, Rejected }

class _TasksState extends State<Tasks> {
  TaskStatus _selectedStatus = TaskStatus.Assigned;
  List<TaskModel> _allTasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await TaskService.getMyTasks();
      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load tasks';
        _isLoading = false;
      });
    }
  }

  List<TaskModel> get _filteredTasks {
    final statusStr = _selectedStatus.name.toLowerCase();
    return _allTasks.where((task) => task.status == statusStr).toList();
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
            Text(
              'Task History',
              style: AppTheme.mainFont(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track all your volunteer activities',
              style: AppTheme.mainFont(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Tab Selector
            Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(27),
                boxShadow: AppTheme.softShadow,
              ),
              child: Stack(
                children: [
                  // Animated Slider Pill
                  AnimatedAlign(
                    alignment: Alignment(
                      (_selectedStatus.index / (TaskStatus.values.length - 1)) *
                              2 -
                          1,
                      0,
                    ),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: FractionallySizedBox(
                      widthFactor: 1 / TaskStatus.values.length,
                      heightFactor: 1.0,
                      child: Container(
                        margin: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Clickable Text Labels
                  Row(
                    children: TaskStatus.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      final count = _allTasks
                          .where((t) => t.status == status.name.toLowerCase())
                          .length;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: AppTheme.mainFont(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                  ),
                                  child: Text(status.name),
                                ),
                                if (count > 0 && !_isLoading)
                                  Text(
                                    '($count)',
                                    style: AppTheme.mainFont(
                                      fontSize: 9,
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content Area
            Expanded(child: _buildTaskContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskContent() {
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
              onPressed: _fetchTasks,
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

    final tasks = _filteredTasks;

    if (tasks.isEmpty) {
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
                _getIconForStatus(_selectedStatus),
                size: 56,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${_selectedStatus.name} Tasks',
              style: AppTheme.mainFont(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getMessageForStatus(_selectedStatus),
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
      onRefresh: _fetchTasks,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskScreen(task: task)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
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
                  Icon(
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (task.timeAgo.isNotEmpty)
                  Text(
                    task.timeAgo,
                    style: AppTheme.mainFont(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: AppTheme.mainFont(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.Assigned:
        return Icons.assignment_ind_rounded;
      case TaskStatus.Accepted:
        return Icons.thumb_up_alt_rounded;
      case TaskStatus.Completed:
        return Icons.task_alt_rounded;
      case TaskStatus.Rejected:
        return Icons.cancel_outlined;
    }
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

  String _getMessageForStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.Assigned:
        return 'Tasks assigned to you will appear here';
      case TaskStatus.Accepted:
        return 'Tasks you\'ve accepted will be shown here';
      case TaskStatus.Completed:
        return 'Your completed tasks will be listed here';
      case TaskStatus.Rejected:
        return 'Tasks you\'ve declined will appear here';
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return AppTheme.textSecondary;
    }
  }
}
