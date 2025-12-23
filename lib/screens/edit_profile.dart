import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/screens/account_page.dart';
import 'package:http_parser/http_parser.dart'; // <--- ADD THIS

class EditProfileScreen extends StatefulWidget {
  final String? userId; // Optional - will fetch from storage if not provided

  const EditProfileScreen({super.key, this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String? _serverImagePath;
  final Color secondaryColor = const Color(0xFFE0F2F1);

  // Form Controllers
  final TextEditingController _nameController = TextEditingController(text: "");
  final TextEditingController _emailController = TextEditingController(
    text: "",
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "",
  );
  final TextEditingController _addressController = TextEditingController(
    text: "",
  );

  // Dropdown state for skill selection
  String? _selectedSkill;

  File? _selectedImage;
  bool _isLoading = false;
  String? _userId; // Store the user ID

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  // Initialize user ID - either from parameter or from storage
  // Initialize user ID - either from parameter, storage, or API via Token
  Future<void> _initializeUserId() async {
    // 1. Check if ID was passed as a parameter
    if (widget.userId != null) {
      _userId = widget.userId;
      _loadUserProfile();
      return;
    }

    // 2. Try to get ID from SharedPreferences
    await _getUserIdFromStorage();

    // 3. FALLBACK: If storage didn't have the ID, try fetching it via API using the Token
    if (_userId == null) {
      print("User ID not found in storage, attempting to fetch via Token...");
      _userId = await _getCurrentUserIdFromAPI();
    }

    // 4. Final check
    if (_userId != null) {
      _loadUserProfile();
    } else {
      _showErrorDialog('User not logged in');
    }
  }

  // Method 1: Get user ID from SharedPreferences (most common)
  Future<void> _getUserIdFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getString('user_id');
        // You might also store other user data:
        // String? token = prefs.getString('auth_token');
        // String? email = prefs.getString('user_email');
      });
    } catch (e) {
      print('Error getting user ID from storage: $e');
    }
  }

  // Method 2: Get user ID from login API response
  // Call this after successful login to store the user ID
  static Future<void> saveUserIdAfterLogin(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('auth_token', token);
    // Store other user data as needed
  }

  // Method 3: Get current user info from API using stored token
  Future<String?> _getCurrentUserIdFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for 'jwt_token' specifically based on your previous logs
      final token =
          prefs.getString(kTokenStorageKey) ??
          prefs.getString('auth_token') ??
          prefs.getString(kTokenStorageKey);

      if (token == null) return null;

      final response = await http.get(
        Uri.parse(
          '$kBaseUrl/public/profile',
        ), // Ensure this endpoint returns the user object with an 'id'
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle nested data if your API returns { "success": true, "data": { ... } }
        final userData = data['data'] ?? data;
        final userId = userData['id']?.toString();

        if (userId != null) {
          await prefs.setString(
            'user_id',
            userId,
          ); // Save it so next time it's faster
          return userId;
        }
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  // Load existing profile data using user ID
  // NEW CODE (Fixes the error)
  Future<void> _loadUserProfile() async {
    // 1. Basic checks
    if (_userId == null) {
      // Even if userId is null, we can still try to load profile using just the token
      // because the backend endpoint '/profile' relies on the token, not the ID param.
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString('jwt_token') ?? prefs.getString('auth_token');

      // 2. USE THE CORRECT ENDPOINT FROM YOUR ROUTER CODE
      // Backend: router.get('/profile', protect(...), getUserProfile)
      final response = await http.get(
        Uri.parse('$kBaseUrl/public/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Profile Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['data'] ?? data;

        // 3. Populate the controllers
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text =
              userData['phoneNumber'] ?? userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _selectedSkill = userData['skill'];
          _serverImagePath = userData['profileImage'];

          // IMPORTANT: Ensure we have the ID for the UPDATE step later
          if (_userId == null && userData['id'] != null) {
            _userId = userData['id'].toString();
          }
        });
      } else {
        _showErrorDialog('Failed to load profile');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  // Save profile data to API using user ID
  // Save profile data (Text + Image) using MultipartRequest
  Future<void> _saveProfile() async {
    // 1. Safety Check
    if (_userId == null) {
      _showErrorDialog('User ID is missing. Please reload the page.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Get the valid token
      final token =
          prefs.getString(kTokenStorageKey) ?? prefs.getString('auth_token');

      // 2. Create Multipart Request
      // 'PUT' matches your router.put()
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$kBaseUrl/public/update/$_userId'),
      );

      // 3. Add Headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        // Note: Do NOT set 'Content-Type': 'application/json' here.
        // Flutter sets the correct multipart boundary automatically.
      });

      // 4. Add Text Fields
      // Validating and adding only if not empty to be safe
      if (_nameController.text.isNotEmpty) {
        request.fields['name'] = _nameController.text;
      }
      if (_emailController.text.isNotEmpty) {
        request.fields['email'] = _emailController.text;
      }
      if (_addressController.text.isNotEmpty) {
        request.fields['address'] = _addressController.text;
      }
      if (_phoneController.text.isNotEmpty) {
        request.fields['phoneNumber'] = _phoneController.text;
      }
      request.fields['skill'] = _selectedSkill ?? 'other';

      // 5. Add Image File (If selected)
      if (_selectedImage != null) {
        // We use fromPath because it's easier and safer
        var multipartFile = await http.MultipartFile.fromPath(
          'profile_image',
          _selectedImage!.path,

          // 👇 THIS IS THE FIX: Explicitly tell the server this is a JPEG image
          contentType: MediaType('image', 'jpeg'),
        );

        request.files.add(multipartFile);
      }

      print("Sending Multipart Request...");
      print("Fields: ${request.fields}");
      if (_selectedImage != null)
        print("File attached: ${_selectedImage!.path}");

      // 6. Send Request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog('Profile updated successfully!');
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _showErrorDialog(errorData['message'] ?? 'Unable to update data');
        } catch (_) {
          _showErrorDialog('Server Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print("Save Error: $e");
      _showErrorDialog('Connection Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper to handle the API response
  void _handleResponse(http.Response response) {
    print("Update Status: ${response.statusCode}");
    print("Update Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      _showSuccessDialog('Profile updated successfully!');
    } else {
      // Try to parse the error message from the server
      try {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Unable to update data');
      } catch (_) {
        _showErrorDialog(
          'Unable to update data (Status: ${response.statusCode})',
        );
      }
    }
  }

  // Alternative: Save without image upload (JSON only) using user ID
  Future<void> _saveProfileJSON() async {
    if (_userId == null) {
      _showErrorDialog('User ID not found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse('$kBaseUrl/profile/update/$_userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'skill': _selectedSkill,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog('Profile updated successfully!');
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    // 1. If user just picked a local image, show that
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Image.file(
          _selectedImage!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    // 2. If server has an image, show that
    if (_serverImagePath != null && _serverImagePath!.isNotEmpty) {
      // Fix backslashes for URL (Windows/Nodejs issue)
      final cleanPath = _serverImagePath!.replaceAll('\\', '/');

      return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Image.network(
          '$kImageUrl/$cleanPath', // Combine Base URL + Image Path
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image fails to load
            return const Icon(
              Icons.account_circle_rounded,
              size: 120,
              color: Colors.grey,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 120,
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    }

    // 3. Default Icon (if no image exists)
    return const Icon(
      Icons.account_circle_rounded,
      size: 120,
      color: Colors.grey, // Optional: makes it look better
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              "Save",
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Profile Image Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 4),
                          ),
                        ),
                        // ✅ CORRECT: The function handles everything
                        _buildProfileImage(),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: InkWell(
                              onTap: _pickImage,
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Form Fields
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      EditField(
                        controller: _nameController,
                        hintText: "Enter Your Full Name",
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'E-mail',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      EditField(
                        controller: _emailController,
                        hintText: "Enter Your E-mail",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      EditField(
                        controller: _addressController,
                        hintText: "Enter Your Address",
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        "Skill",
                        "Select your skill",
                        _selectedSkill,
                        [
                          'police',
                          'nss',
                          'fire force',
                          'ncc',
                          'student police',
                          'scout',
                          'other',
                        ],
                        (String? newValue) {
                          setState(() {
                            _selectedSkill = newValue;
                          });
                        },
                        Icons.work_outline,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      EditField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        hintText: "+91 ",
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Main Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[500]),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.blue),
              gapPadding: BorderSide.strokeAlignCenter,
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

class EditField extends StatefulWidget {
  const EditField({
    super.key,
    this.onChanged,
    this.hintText,
    this.keyboardType,
    this.controller,
  });

  final void Function(String)? onChanged;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  @override
  State<EditField> createState() => _EditFieldState();
}

class _EditFieldState extends State<EditField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          gapPadding: BorderSide.strokeAlignCenter,
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

// ==================== EXAMPLE LOGIN SCREEN ====================
// This shows how to save user ID after successful login

class LoginExample extends StatelessWidget {
  const LoginExample({super.key});

  Future<void> _login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-api.com/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['user']['id'].toString());
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_email', data['user']['email']);
        await prefs.setString('user_name', data['user']['name']);

        // Now you can navigate to any screen and access the user ID
      }
    } catch (e) {
      print('Login error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Login Example - See code for implementation')),
    );
  }
}
