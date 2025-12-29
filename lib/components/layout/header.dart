import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:volunteer_app/screens/notification_screen.dart';
import 'package:volunteer_app/services/notification_service.dart';

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
      print('>>> Header: Loading unread count...');
      final count = await NotificationService.getUnreadCount();
      print('>>> Header: Got unread count: $count');
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
        print('>>> Header: State updated, _unreadCount = $_unreadCount');
      }
    } catch (e) {
      print('>>> Header: Error loading unread count: $e');
    }
  }

  void _navigateToNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const NotificationScreen()));
    // Refresh count when returning from notifications screen
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image(
                  fit: BoxFit.cover,
                  width: 35,
                  height: 35,
                  image: const AssetImage('assets/images/logo3.png'),
                ),
                const Text(
                  'Volenteer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const Text(
                  'App',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Notification icon with badge
                IconButton(
                  iconSize: 32,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_active),
                      // Badge showing unread count
                      if (_unreadCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              _unreadCount > 99 ? '99+' : '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _navigateToNotifications,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
