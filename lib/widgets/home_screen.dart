import 'package:flutter/material.dart';
import 'package:volunteer_app/components/layout/header.dart';
import 'package:volunteer_app/screens/Dashboard.dart';
import 'package:volunteer_app/screens/Map.dart';
import 'package:volunteer_app/screens/Tasks.dart';
import 'package:volunteer_app/screens/account_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Initialize the current index

  final List<Widget> _pages = [
    const Dashboard(),
    const Tasks(),
    const Map(),
    const Account(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 222, 222),
      appBar: Header(),
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex, // Highlight the current tab
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the current index on tap
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'DashBoard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_toggle_off),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.near_me_sharp),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
