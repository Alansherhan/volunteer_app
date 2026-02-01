import 'package:flutter/material.dart';
import 'package:volunteer_app/models/task_model.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class TaskDetailsPreviewScreen extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onClaim;

  const TaskDetailsPreviewScreen({
    super.key,
    required this.task,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Task Preview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reusing similar UI structure as TaskScreen but read-only
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColorLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                task.taskTypeLabel,
                                style: AppTheme.mainFont(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (task.volunteersNeeded > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${task.volunteersNeeded} Volunteers Needed',
                                  style: AppTheme.mainFont(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          task.taskName,
                          style: AppTheme.mainFont(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.flag_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.priorityLabel,
                              style: AppTheme.mainFont(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // For donation tasks: show both pickup and delivery locations
                  if (task.taskType == 'donation') ...[
                    // Pickup Location
                    if (task.pickupAddressString != null) ...[
                      _buildLocationRow(
                        title: 'Pickup Location',
                        address: task.pickupAddressString!,
                        iconColor: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Delivery Location
                    if (task.deliveryAddressString != null) ...[
                      _buildLocationRow(
                        title: 'Delivery Location',
                        address: task.deliveryAddressString!,
                        iconColor: Colors.green,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Fallback to single location
                    if (task.pickupAddressString == null &&
                        task.deliveryAddressString == null &&
                        task.location != null) ...[
                      _buildLocationRow(
                        title: 'Location',
                        address: task.location!,
                        iconColor: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],

                  // For aid tasks: show single location
                  if (task.taskType == 'aid' && task.location != null) ...[
                    _buildLocationRow(
                      title: 'Location',
                      address: task.location!,
                      iconColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 12),
                  Text(
                    'Description',
                    style: AppTheme.mainFont(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Show description from aid request or generic
                  Text(
                    task.taskType == 'aid' && task.aidRequest != null
                        ? (task.aidRequest!['description'] ??
                              'No description provided')
                        : 'Please review the details before claiming.',
                    style: AppTheme.mainFont(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Claim Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Claim this Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a location row widget for the preview
  Widget _buildLocationRow({
    required String title,
    required String address,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on_rounded, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.mainFont(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: AppTheme.mainFont(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
