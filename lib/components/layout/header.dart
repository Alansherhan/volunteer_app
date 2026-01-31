import 'package:flutter/material.dart';
import 'package:volunteer_app/screens/notification_screen.dart';
import 'package:volunteer_app/services/notification_service.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

class _HeaderState extends State<Header> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _navigateToNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/notifications'),
        builder: (context) => const NotificationScreen(),
      ),
    );
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo and App Name
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo3.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Volunteer',
                  style: AppTheme.mainFont(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'App',
                  style: AppTheme.mainFont(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            // Notification Button
            GestureDetector(
              onTap: _navigateToNotifications,
              child: Container(
                padding: const EdgeInsets.all(10),
                // decoration: BoxDecoration(
                //   color: AppTheme.surfaceColor,
                //   borderRadius: BorderRadius.circular(14),
                //   boxShadow: AppTheme.softShadow,
                // ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textPrimary,
                      size: 28,
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.surfaceColor,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 10,
                            minHeight: 14,
                          ),
                          child: Text(
                            _unreadCount > 99 ? '99+' : '$_unreadCount',
                            style: AppTheme.mainFont(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
