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
// import 'package:animations/animations.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  File? _selectedImage; // Image picked locally
  String? _serverImagePath; // Image path from Server DB

  bool val = true;
  String userName = 'Loading...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Function to pick image (Optional, if you want to allow changing it here too)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      // Note: If you pick an image here, you usually want to upload it immediately
      // or pass it to the edit screen. For now, this just updates the UI locally.
    }
  }

  Future<void> _fetchUserProfile() async {
    const profileEndpoint = '$kBaseUrl/public/profile';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString(kTokenStorageKey) ?? prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        setState(() {
          userName = 'Not logged in';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(profileEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData =
            data['data']; // Access the 'data' object inside response

        setState(() {
          userName = userData['name'] ?? 'User';
          // 1. GET IMAGE PATH FROM SERVER
          _serverImagePath = userData['profileImage'];
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

  Widget _getProfileImageWidget() {
    // 1. If user just picked a new photo from gallery, show that
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    }

    // 2. If we have a valid image path from the server, show that
    if (_serverImagePath != null && _serverImagePath!.isNotEmpty) {
      // FIX: Replace backslashes (\) with forward slashes (/) for URLs
      final cleanPath = _serverImagePath!.replaceAll('\\', '/');

      // Combine Base URL + Path
      // Example: http://192.168.1.5:3000 + / + uploads/image.jpg
      final fullImageUrl = '$kImageUrl/$cleanPath';

      print("Loading Image from: $fullImageUrl"); // Debug print

      return Image.network(
        fullImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If image fails to load (e.g. 404), show icon
          return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
        },
      );
    }

    // 3. Default fallback (if no image exists)
    return const Icon(
      Icons.account_circle_rounded,
      size: 120,
      color: Colors.grey,
    );
  }

  // 2. HELPER TO DECIDE WHICH IMAGE TO SHOW
  ImageProvider _getProfileImage() {
    // Priority 1: User just picked a new image from gallery
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    // Priority 2: User has an image saved on the server
    if (_serverImagePath != null && _serverImagePath!.isNotEmpty) {
      // Clean path (fix backslashes for Windows servers)
      final cleanPath = _serverImagePath!.replaceAll('\\', '/');
      // Construct full URL
      return NetworkImage('$kImageUrl/$cleanPath');
    }

    // Priority 3: Fallback (This won't be reached due to the check in build, but good for safety)
    return const AssetImage('assets/logo3.png');
  }

  void _previewImage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, // Allows the background to remain visible
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.7), // Dims the background
        pageBuilder: (context, _, __) {
          return Center(
            child: Dialog(
              backgroundColor:
                  Colors.transparent, // Keeps the focus on the image
              insetPadding: const EdgeInsets.all(10),
              child: Hero(
                tag: 'profile-image', // Must match your source tag exactly
                child: Container(
                  width: double.infinity,
                  height: 400,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _getProfileImage(),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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

                    // --- 3. UPDATED IMAGE WIDGET ---
                    InkWell(
                      onTap: () {
                        _previewImage();
                      },
                      child: Hero(
                        tag: 'profile-image',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors
                                .grey[200], // Background for transparent images
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child:
                                _selectedImage == null &&
                                    (_serverImagePath == null ||
                                        _serverImagePath!.isEmpty)
                                ? const Icon(
                                    Icons.account_circle_rounded,
                                    size: 120,
                                    color: Colors.grey,
                                  )
                                : Image(
                                    image: _getProfileImage(),
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // --------------------------------
                    const SizedBox(height: 10),
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
                      onTap: () async {
                        // 4. REFRESH DATA ON RETURN
                        // We wait for the Edit Screen to close...
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        // ...and then fetch the profile again to show updates
                        _fetchUserProfile();
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

              // ... Rest of your code (Activity, Settings, Logout) stays the same ...
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
