import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citcs_training_app/screens/signup_screen.dart'; // Correct import for SignupPageWidget
import 'package:citcs_training_app/screens/players_screen.dart';
import 'package:citcs_training_app/screens/coach_screen.dart'; // Import for CoachScreen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool _isPasswordVisible = false; // State variable for password visibility

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Method to handle login
  Future<void> _handleLogin() async {
    try {
      // Sign in with email and password
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Get user role from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).get();

      if (userDoc.exists) {
        String userRole = userDoc['role'];

        // Navigate to the appropriate screen based on the user role
        if (userRole == 'Player') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PlayersPageWidget()),
          );
        } else if (userRole == 'Coach') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CoachesPageWidget()), // Ensure CoachScreen is imported
          );
        } else {
          // Handle unknown roles if necessary
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown role. Please contact support.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please sign up.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 352,
              height: 540,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and welcome text
                    Image.asset('assets/images/logo.png', width: 140, height: 130),
                    const SizedBox(height: 1),
                    Text('Hello Athlete!', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('Welcome to CITCS Trainer Application', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                    const SizedBox(height: 10),

                    // Email text field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Password text field
                    TextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Login button
                    ElevatedButton(
                      onPressed: _handleLogin, // Call the login handler
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 130, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color.fromRGBO(22, 22, 22, 100),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Login', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 5),

                    // Navigate to Signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPageWidget()));
                          },
                          child: Text("Sign up", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
