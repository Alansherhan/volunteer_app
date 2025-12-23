import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {},
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.notifications_active,
                        size: 30,
                        color: Colors.red,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Text(
                          //   'New',
                          //   style: TextStyle(color: Colors.blue),
                          // ),
                          Text(
                            'Emergency Alert:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Flood warning for Sector 4 Evacuate ',
                            // maxLines: 2,
                            // style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'immediately.',
                            maxLines: 2,
                            // style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
