import 'package:flutter/material.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final String realTaskId; // The actual MongoDB ID for API calls
  final String title;
  final String location;
  final String type;
  final String status;
  final VoidCallback onTap;
  final Future<void> Function()? onStartTask;
  final bool isLoading;

  const TaskCard({
    super.key,
    required this.taskId,
    this.realTaskId = '',
    required this.title,
    required this.location,
    required this.type,
    this.status = 'assigned',
    required this.onTap,
    this.onStartTask,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppTheme.primaryColor;
    IconData iconData = Icons.assignment_rounded;
    Color bgColor = AppTheme.primaryColor.withOpacity(0.1);

    if (type.toLowerCase().contains('delivery')) {
      statusColor = AppTheme.warningColor;
      iconData = Icons.local_shipping_rounded;
      bgColor = AppTheme.warningColor.withOpacity(0.1);
    } else if (type.toLowerCase().contains('pickup')) {
      statusColor = AppTheme.successColor;
      iconData = Icons.store_rounded;
      bgColor = AppTheme.successColor.withOpacity(0.1);
    } else if (type.toLowerCase().contains('visit')) {
      statusColor = AppTheme.secondaryColor;
      iconData = Icons.people_rounded;
      bgColor = AppTheme.secondaryColor.withOpacity(0.1);
    } else if (type.toLowerCase().contains('aid')) {
      statusColor = Colors.red;
      iconData = Icons.medical_services_rounded;
      bgColor = Colors.red.withOpacity(0.1);
    } else if (type.toLowerCase().contains('donation')) {
      statusColor = AppTheme.successColor;
      iconData = Icons.volunteer_activism_rounded;
      bgColor = AppTheme.successColor.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconData, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            type,
                            style: AppTheme.mainFont(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: AppTheme.mainFont(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Title
                Text(
                  title,
                  style: AppTheme.mainFont(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: AppTheme.mainFont(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Task ID
                    Text(
                      taskId,
                      style: AppTheme.mainFont(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : (onStartTask ?? onTap),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getButtonColor(status),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primaryColor
                          .withOpacity(0.5),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getButtonText(status),
                                style: AppTheme.mainFont(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(_getButtonIcon(status), size: 18),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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

  Color _getButtonColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return AppTheme.primaryColor;
      case 'accepted':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getButtonText(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'Accept Task';
      case 'accepted':
        return 'Mark Complete';
      case 'completed':
        return 'View Details';
      default:
        return 'View Details';
    }
  }

  IconData _getButtonIcon(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Icons.check_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }
}
