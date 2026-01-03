import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:volunteer_app/models/task_model.dart';
import 'package:volunteer_app/screens/map_screen.dart';
import 'package:volunteer_app/services/task_service.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class TaskScreen extends StatefulWidget {
  final TaskModel task;

  const TaskScreen({super.key, required this.task});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _isLoading = false;
  File? _selectedProofImage;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);

    final success = await TaskService.updateTaskStatus(
      widget.task.id,
      newStatus,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'accepted'
                  ? 'Task started!'
                  : newStatus == 'completed'
                  ? 'Task completed!'
                  : 'Task rejected',
            ),
            backgroundColor: newStatus == 'rejected'
                ? Colors.red
                : AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update task'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProofImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _completeWithProof() async {
    if (_selectedProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a proof photo first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Navigator.pop(context); // Close the bottom sheet

    final success = await TaskService.completeTaskWithProof(
      widget.task.id,
      _selectedProofImage!,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task completed successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return to task list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete task. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCompletionDialog() {
    _selectedProofImage = null; // Reset selection
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Upload Proof Photo',
                  style: AppTheme.mainFont(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take or select a photo as proof of task completion',
                  style: AppTheme.mainFont(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Image Preview or Placeholder
                if (_selectedProofImage != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedProofImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedProofImage = null);
                            setModalState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: AppTheme.primaryColor.withOpacity(0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No photo selected',
                          style: AppTheme.mainFont(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Camera & Gallery Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _pickImage(ImageSource.camera);
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(
                          'Camera',
                          style: AppTheme.mainFont(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _pickImage(ImageSource.gallery);
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.photo_library_rounded),
                        label: Text(
                          'Gallery',
                          style: AppTheme.mainFont(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedProofImage != null
                        ? () => _completeWithProof()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.textMuted.withOpacity(
                        0.3,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Complete Task',
                          style: AppTheme.mainFont(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Task Details',
          style: AppTheme.mainFont(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColorLight],
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          task.status.toUpperCase(),
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

            // Task ID
            _buildInfoCard(
              icon: Icons.tag_rounded,
              title: 'Task ID',
              value: '#${task.id.substring(task.id.length - 8).toUpperCase()}',
            ),
            const SizedBox(height: 12),

            // Location with Map Button
            if (task.location != null) _buildLocationCard(task.location!),
            if (task.location != null) const SizedBox(height: 12),

            // Created At
            if (task.createdAt != null)
              _buildInfoCard(
                icon: Icons.access_time_rounded,
                title: 'Assigned',
                value: task.timeAgo,
              ),
            if (task.createdAt != null) const SizedBox(height: 12),

            // Priority
            _buildInfoCard(
              icon: Icons.priority_high_rounded,
              title: 'Priority',
              value: task.priority.toUpperCase(),
              valueColor: _getPriorityColor(task.priority),
            ),
            const SizedBox(height: 24),

            // Details Section Header
            Text(
              'Details',
              style: AppTheme.mainFont(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Aid Request Details
            if (task.taskType == 'aid' && task.aidRequest != null) ...[
              _buildAidRequestDetails(task.aidRequest!),
            ],

            // Donation Request Details
            if (task.taskType == 'donation' &&
                task.donationRequest != null) ...[
              _buildDonationRequestDetails(task.donationRequest!),
            ],

            // Image if available
            if (task.imageUrl != null && task.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageCard(task.imageUrl!),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            if (task.status == 'pending') ...[
              _buildActionButton(
                label: 'Start Task',
                icon: Icons.play_arrow_rounded,
                color: AppTheme.primaryColor,
                onPressed: () => _updateStatus('accepted'),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                label: 'Reject Task',
                icon: Icons.close_rounded,
                color: Colors.red,
                isOutlined: true,
                onPressed: () => _updateStatus('rejected'),
              ),
            ] else if (task.status == 'accepted') ...[
              _buildActionButton(
                label: 'Mark as Complete',
                icon: Icons.check_circle_rounded,
                color: AppTheme.successColor,
                onPressed: () => _showCompletionDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.mainFont(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.mainFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String location) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: AppTheme.mainFont(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: AppTheme.mainFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const Map_Screen()),
                );
              },
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(
                'View on Map',
                style: AppTheme.mainFont(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                foregroundColor: AppTheme.primaryColor,
                elevation: 0,
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: isOutlined ? color : Colors.white,
          elevation: isOutlined ? 0 : 2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isOutlined
                ? BorderSide(color: color, width: 2)
                : BorderSide.none,
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isOutlined ? color : Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTheme.mainFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return AppTheme.primaryColor;
      default:
        return AppTheme.textPrimary;
    }
  }

  Widget _buildAidRequestDetails(Map<String, dynamic> aidRequest) {
    final calamity = aidRequest['calamity'];
    final calamityName =
        calamity?['calamityName'] ??
        aidRequest['calamityType']?.toString() ??
        'Unknown';
    final description = aidRequest['description'] ?? '';
    final formattedAddress = aidRequest['formattedAddress'] ?? '';
    final requester = aidRequest['aidRequestedBy'];
    final requesterName = requester is Map
        ? (requester['name'] ?? 'Unknown')
        : 'Unknown';
    final requesterPhone = requester is Map
        ? (requester['phone'] ?? requester['email'] ?? '')
        : '';
    final imageUrl = aidRequest['imageUrl'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calamity Type
          _buildDetailRow(
            icon: Icons.warning_amber_rounded,
            label: 'Calamity Type',
            value: calamityName,
            iconColor: Colors.orange,
          ),
          const SizedBox(height: 12),

          // Requester Info
          _buildDetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Requested By',
            value: requesterName,
            iconColor: AppTheme.primaryColor,
          ),

          if (requesterPhone.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: requesterPhone,
              iconColor: Colors.green,
            ),
          ],

          if (formattedAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.home_outlined,
              label: 'Full Address',
              value: formattedAddress,
              iconColor: AppTheme.primaryColor,
            ),
          ],

          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: AppTheme.mainFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTheme.mainFont(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Aid Request Image
          if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonationRequestDetails(Map<String, dynamic> donationRequest) {
    final title = donationRequest['title'] ?? '';
    final description = donationRequest['description'] ?? '';
    final donationType = donationRequest['donationType'] ?? 'item';
    final amount = donationRequest['amount'];
    final fulfilledAmountRaw = donationRequest['fulfilledAmount'] ?? 0;
    final fulfilledAmount = fulfilledAmountRaw is int
        ? fulfilledAmountRaw
        : int.tryParse(fulfilledAmountRaw.toString()) ?? 0;
    final itemDetails = donationRequest['itemDetails'] as List<dynamic>? ?? [];
    final deadline = donationRequest['deadline'];
    final upiNumber = donationRequest['upiNumber'];
    final requester =
        donationRequest['requestedUser'] ?? donationRequest['requestedBy'];
    final requesterName = requester is Map
        ? (requester['name'] ?? 'Unknown')
        : 'Unknown';
    final requesterPhone = requester is Map
        ? (requester['phone'] ?? requester['email'] ?? '')
        : '';
    final proofImages = donationRequest['proofImages'] as List<dynamic>? ?? [];
    final formattedAddress = _getFormattedAddress(donationRequest['address']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: AppTheme.mainFont(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Donation Type
          _buildDetailRow(
            icon: donationType == 'cash'
                ? Icons.attach_money_rounded
                : Icons.inventory_2_outlined,
            label: 'Donation Type',
            value: donationType == 'cash' ? 'Cash Donation' : 'Item Donation',
            iconColor: donationType == 'cash'
                ? Colors.green
                : AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),

          // Amount (for cash donations)
          if (donationType == 'cash' && amount != null) ...[
            _buildDetailRow(
              icon: Icons.currency_rupee_rounded,
              label: 'Amount Requested',
              value: '₹${amount.toString()}',
              iconColor: Colors.green,
            ),
            if (fulfilledAmount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Fulfilled: ₹$fulfilledAmount / ₹$amount',
                  style: AppTheme.mainFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // UPI Number (for cash donations)
          if (donationType == 'cash' &&
              upiNumber != null &&
              upiNumber.toString().isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'UPI Number',
              value: upiNumber.toString(),
              iconColor: Colors.purple,
            ),
            const SizedBox(height: 12),
          ],

          // Item Details (for item donations)
          if (donationType == 'item' && itemDetails.isNotEmpty) ...[
            Text(
              'Items Needed',
              style: AppTheme.mainFont(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...itemDetails.map((item) {
              final itemName = item['name'] ?? item['itemName'] ?? 'Item';
              final quantityRaw = item['quantity'] ?? 1;
              final quantity = quantityRaw is int
                  ? quantityRaw
                  : int.tryParse(quantityRaw.toString()) ?? 1;
              final unit = item['unit'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$itemName${quantity > 1 ? ' x$quantity' : ''}${unit.isNotEmpty ? ' $unit' : ''}',
                      style: AppTheme.mainFont(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
          ],

          // Requester Info
          _buildDetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Requested By',
            value: requesterName,
            iconColor: AppTheme.primaryColor,
          ),

          // if (requesterPhone.isNotEmpty) ...[
          //   const SizedBox(height: 12),
          //   _buildDetailRow(
          //     icon: Icons.phone_outlined,
          //     label: 'Contact',
          //     value: requesterPhone,
          //     iconColor: Colors.green,
          //   ),
          // ],

          // Address
          if (formattedAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.home_outlined,
              label: 'Delivery Address',
              value: formattedAddress,
              iconColor: AppTheme.primaryColor,
            ),
          ],

          // Deadline
          if (deadline != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.schedule_rounded,
              label: 'Deadline',
              value: _formatDeadline(deadline),
              iconColor: Colors.red,
            ),
          ],

          // Description
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: AppTheme.mainFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTheme.mainFont(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Proof Images
          if (proofImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Proof Images',
              style: AppTheme.mainFont(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: proofImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < proofImages.length - 1 ? 8 : 0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        proofImages[index].toString(),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 120,
                          height: 120,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.mainFont(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.mainFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 100,
            color: AppTheme.surfaceColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Image not available',
                    style: AppTheme.mainFont(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFormattedAddress(dynamic address) {
    if (address == null) return '';
    if (address is! Map) return '';

    final parts = <String>[];
    if (address['addressLine1'] != null &&
        address['addressLine1'].toString().isNotEmpty) {
      parts.add(address['addressLine1'].toString());
    }
    if (address['addressLine2'] != null &&
        address['addressLine2'].toString().isNotEmpty) {
      parts.add(address['addressLine2'].toString());
    }
    if (address['addressLine3'] != null &&
        address['addressLine3'].toString().isNotEmpty) {
      parts.add(address['addressLine3'].toString());
    }
    if (address['pinCode'] != null &&
        address['pinCode'].toString().isNotEmpty) {
      parts.add('- ${address['pinCode']}');
    }

    return parts.join(', ');
  }

  String _formatDeadline(dynamic deadline) {
    if (deadline == null) return '';

    DateTime? date;
    if (deadline is String) {
      date = DateTime.tryParse(deadline);
    } else if (deadline is DateTime) {
      date = deadline;
    }

    if (date == null) return deadline.toString();

    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days left';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
