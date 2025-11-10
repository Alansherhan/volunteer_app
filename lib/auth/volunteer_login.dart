import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:volunteer_app/auth/volunteer_signup.dart';

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
          image: DecorationImage(
            alignment: AlignmentGeometry.topCenter,
            fit: BoxFit.cover,
            image: AssetImage('assets/images/pexels-artempodrez-7233099.jpg'),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassmorphicContainer(
                height: 350,
                width: double.infinity,

                borderRadius: 32,
                blur: 1.5,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white38.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Colors.white24.withOpacity(0.2),
                    Colors.white70.withOpacity(0.2),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.account_circle, size: 95),
                      Text('LOGIN'),
                      SizedBox(height: 24),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          // filled: true,
                          hintText: "Email",
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.key),
                          // filled: true,
                          hintText: "Password",
                        ),
                      ),

                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Text('LOGIN'),
                        ),
                      ),
                    ],
                  ),
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
