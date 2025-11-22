import 'package:flutter/material.dart';

import 'package:volunteer_app/auth/volunteer_login.dart';
import 'package:volunteer_app/auth/volunteer_signup.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

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
                // Image(
                //   image: AssetImage('assets/images/logo.jpg'),
                //   height: 12,
                // ),
                Image(
                  // alignment: AlignmentGeometry.topCenter,
                  // fit: BoxFit.cover,
                  //  width: 1,
                  //   height: 1,
                  image: AssetImage('assets/images/logo3.png'),
                ),
                Text(
                  'Volenteer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                Text(
                  'App',
                  style: TextStyle(
                    color: const Color.fromARGB(
                      255,
                      4,
                      212,
                      245,
                    ).withOpacity(1.0),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),

            Row(
              children: [
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.notifications_active),
                  onPressed: () {
                    // ...
                  },
                ),
                PopupMenuButton<String>(
                  // We use your original icon and size
                  iconSize: 32,
                  // icon: const Icon(Icons.account_circle),

                  // This function is called when a user selects an item from the menu
                  onSelected: (String value) {
                    if (value == 'login') {
                      // Navigate to the Login Screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    } else if (value == 'signup') {
                      // Navigate to the Sign Up Screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    }
                  },

                  // This builds the menu with your Login and Sign Up options
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'login',
                          child: Text('Login'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'signup',
                          child: Text('Sign Up'),
                        ),
                      ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(48);
}
