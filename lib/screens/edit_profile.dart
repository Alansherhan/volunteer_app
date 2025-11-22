import 'package:flutter/material.dart';
import 'package:volunteer_app/screens/account_page.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EditProfileScreen(),
    ),
  );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Using the primary color from your screenshot (Teal/Cyan)
  final Color primaryColor = const Color(0xFF26A69A);
  final Color secondaryColor = const Color(0xFFE0F2F1);

  // Form Controllers (Pre-filled with data from your image)
  final TextEditingController _nameController = TextEditingController(
    text: "Rajesh Kumar",
  );
  final TextEditingController _roleController = TextEditingController(
    text: "Registered Volunteer",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "rajesh.kumar@example.com",
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "+91 98765 43210",
  );

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
          // Optional 'Save' text button in AppBar
          TextButton(
            onPressed: () {
              // TODO: Add save logic here
            },
            child: Text(
              "Save",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- Profile Image Section ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 4),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: InkWell(
                        child: const Icon(
                          Icons.camera_alt,
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

            // --- Form Fields ---
            _buildTextField(
              "Full Name",
              "Enter your full name",
              _nameController,
              Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              "Role / Title",
              "Enter your role",
              _roleController,
              Icons.work_outline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              "Email Address",
              "Enter email",
              _emailController,
              Icons.email_outlined,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              "Phone Number",
              "Enter phone number",
              _phoneController,
              Icons.phone_outlined,
            ),

            const SizedBox(height: 40),

            // --- Main Action Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Save Logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const Account(),
                      ),
                    );
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to keep code clean
  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
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
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[500]),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}
