import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/auth/volunteer_login.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/screens/change_password_page.dart';
import 'package:volunteer_app/screens/edit_profile.dart';
import 'package:http/http.dart' as http;

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  File? _selectedImage;

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  bool val = true;

  String userName = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    const profile = '$kBaseUrl/public/profile';
    try {
      final prefs = await SharedPreferences.getInstance();

      // 🔍 DEBUG: Check what's in storage
      print('==================== ACCOUNT PAGE INIT ====================');
      print('All keys: ${prefs.getKeys()}');
      print('kTokenStorageKey value: "$kTokenStorageKey"');

      // Try both possible token keys
      final token =
          prefs.getString(kTokenStorageKey) ?? prefs.getString('auth_token');

      print('Token found: ${token != null}');
      if (token != null) {
        print('Token: ${token.substring(0, 20)}...');
      }
      print('=======================================================');

      if (token == null || token.isEmpty) {
        setState(() {
          userName = 'Not logged in';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(profile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Profile API Response status: ${response.statusCode}');
      print('Profile API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['data']['name'] ?? 'User';
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'Error loading name';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Error loading name';
        isLoading = false;
      });
      print('Error fetching user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Text('Profile', style: TextStyle(fontSize: 30)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        _pickImage();
                      },
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.file(
                                _selectedImage!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.account_circle_rounded, size: 120),
                    ),
                    Text(userName, style: const TextStyle(fontSize: 30)),
                    const Text(
                      'Registered Volunteer',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit Profile'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Change Password'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'My Activity',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.assignment),
                      subtitle: const Text(
                        '0',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      title: const Text(
                        'Tasks Completed',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Settings & Preferences',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: Colors.blue,
                      value: val,
                      onChanged: (bool? value) {
                        setState(() {
                          val = value!;
                        });
                      },
                      title: const Text('Notification'),
                      secondary: const Icon(Icons.notification_add),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (mounted) {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (context) => const LoginScreen(),
                        ),
                        (r) => false,
                      );
                    }
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
