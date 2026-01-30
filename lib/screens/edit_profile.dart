import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/screens/account_page.dart';
import 'package:volunteer_app/theme/app_theme.dart';
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

  // Function to show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose Profile Photo',
              style: AppTheme.mainFont(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.mainFont(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Function to pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

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
      final token = prefs.getString(kTokenStorageKey);

      // 2. Create Multipart Request
      // 'PUT' matches your router.put()
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$kBaseUrl/public/update'),
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
      final token = prefs.getString(kTokenStorageKey);

      final response = await http.put(
        Uri.parse('$kBaseUrl/profile/update/$_userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
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
                      image: (_getProfileImage()),
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading && _nameController.text.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : CustomScrollView(
              slivers: [
                // Gradient Header
                SliverToBoxAdapter(child: _buildHeader()),
                // Form Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Personal Information Section
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 16),
                      _buildInputCard(
                        icon: Icons.person_outline_rounded,
                        iconColor: Colors.indigo,
                        label: 'Full Name',
                        child: _buildTextField(
                          controller: _nameController,
                          hint: 'Enter your full name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputCard(
                        icon: Icons.email_outlined,
                        iconColor: Colors.blue,
                        label: 'Email Address',
                        child: _buildTextField(
                          controller: _emailController,
                          hint: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputCard(
                        icon: Icons.phone_outlined,
                        iconColor: Colors.green,
                        label: 'Phone Number',
                        child: _buildTextField(
                          controller: _phoneController,
                          hint: '+91 Enter your phone number',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Location Section
                      _buildSectionTitle('Location'),
                      const SizedBox(height: 16),
                      _buildInputCard(
                        icon: Icons.location_on_outlined,
                        iconColor: Colors.red,
                        label: 'Address',
                        child: _buildTextField(
                          controller: _addressController,
                          hint: 'Enter your address',
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Skills Section
                      _buildSectionTitle('Skills & Expertise'),
                      const SizedBox(height: 16),
                      _buildInputCard(
                        icon: Icons.work_outline_rounded,
                        iconColor: Colors.purple,
                        label: 'Primary Skill',
                        child: _buildDropdown(),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      _buildSaveButton(),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.85),
            Colors.indigo.shade400,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
          child: Column(
            children: [
              // App Bar Row
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      textAlign: TextAlign.center,
                      style: AppTheme.mainFont(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Save Button in header
                  TextButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: Text(
                      'Save',
                      style: AppTheme.mainFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isLoading
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Profile Image
              GestureDetector(
                onTap: _previewImage,
                child: Hero(
                  tag: 'profile-image',
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: ClipOval(child: _buildProfileImage()),
                        ),
                      ),
                      // Camera/Gallery Button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_a_photo_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to add or change photo',
                style: AppTheme.mainFont(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTheme.mainFont(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTheme.mainFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTheme.mainFont(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.mainFont(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSkill,
          hint: Text(
            'Select your primary skill',
            style: AppTheme.mainFont(color: Colors.grey.shade400, fontSize: 14),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade600,
          ),
          style: AppTheme.mainFont(fontSize: 15, color: Colors.black87),
          items:
              [
                'police',
                'nss',
                'fire force',
                'ncc',
                'student police',
                'scout',
                'other',
              ].map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      _getSkillIcon(item),
                      const SizedBox(width: 12),
                      Text(_capitalizeFirst(item)),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedSkill = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _getSkillIcon(String skill) {
    IconData iconData;
    Color color;

    switch (skill.toLowerCase()) {
      case 'police':
        iconData = Icons.local_police_rounded;
        color = Colors.blue;
        break;
      case 'fire force':
        iconData = Icons.local_fire_department_rounded;
        color = Colors.orange;
        break;
      case 'ncc':
        iconData = Icons.military_tech_rounded;
        color = Colors.green;
        break;
      case 'nss':
        iconData = Icons.volunteer_activism_rounded;
        color = Colors.red;
        break;
      case 'student police':
        iconData = Icons.school_rounded;
        color = Colors.indigo;
        break;
      case 'scout':
        iconData = Icons.hiking_rounded;
        color = Colors.brown;
        break;
      default:
        iconData = Icons.work_rounded;
        color = Colors.grey;
    }

    return Icon(iconData, color: color, size: 20);
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Colors.indigo.shade600],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveProfile,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Save Changes',
                        style: AppTheme.mainFont(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
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
