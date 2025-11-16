import 'package:flutter/material.dart';
// import 'package:glassmorphism/glassmorphism.dart';
import 'package:volunteer_app/auth/volunteer_signup.dart';
import 'package:volunteer_app/widgets/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // width: double.infinity,
        // height: double.infinity,
        // height: double.infinity,
        decoration: BoxDecoration(
          // image: DecorationImage(
          //   alignment: AlignmentGeometry.topCenter,
          //   fit: BoxFit.cover,
          //   image: AssetImage('assets/images/pexels-artempodrez-7233099.jpg'),
          color: const Color.fromARGB(255, 231, 228, 228),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.account_circle, size: 95),
                    Text('LOGIN'),
                    SizedBox(height: 24),
                    TextFormField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.email_outlined),
                        // filled: true,
                        hintText: "Email",
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.key),
                        // filled: true,
                        hintText: "Password",
                      ),
                    ),

                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                        child: Text('LOG IN'),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  children: [
                    Text("Don't you have an account?,"),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text("Sign Up"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
