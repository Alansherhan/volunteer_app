import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:volunteer_app/auth/volunteer_login.dart';
import 'package:volunteer_app/screens/edit_profile.dart';
// import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  File? _selectedImage;

  // 1. Function to pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // Pick an image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    // Update the UI if the user successfully picked an image
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  bool val = true;

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
                    Text('Profile', style: TextStyle(fontSize: 30)),

                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        _pickImage();
                      },
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadiusGeometry.circular(100),
                              child: Image.file(
                                _selectedImage!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.account_circle_rounded, size: 120),
                    ),
                    Text('Alan Sherhan KP', style: TextStyle(fontSize: 30)),
                    Text(
                      'Registered Volunteer',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Account Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Profile'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.lock),
                      title: Text('Change Password'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'My Activity',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.assignment),
                      subtitle: Text(
                        '0',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      title: Text(
                        'Tasks Completed',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
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
                      title: Text('Notification'),
                      secondary: Icon(Icons.notification_add),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
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
