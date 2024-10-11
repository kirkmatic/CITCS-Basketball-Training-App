import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:citcs_training_app/screens/signup_screen.dart'; // Replace with your actual project name


class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_image.png'), // Path to your background image
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Container behind the logo, texts, email, and password fields
          Center(
            child: Container(
              width: 352,
              height: 540, // Adjusted height
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Transparent white background
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      width: 140,
                      height: 130,
                    ),

                    SizedBox(height: 1),

                    // Text below the logo
                    Text(
                      'Hello Athlete!',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white, // Text color below logo
                      ),
                    ),

                    Text(
                      'Welcome to CITCS Trainer Application',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white, // Text color below logo
                      ),
                    ),

                    SizedBox(height: 10),

                    // Email text field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14, // Reduced font size
                          fontWeight: FontWeight.w500,
                          color: Colors.white, // Label color
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    SizedBox(height: 10),

                    // Password text field
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14, // Reduced font size
                          fontWeight: FontWeight.w500,
                          color: Colors.white, // Label color
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    SizedBox(height: 10),

                    // Login button
                    ElevatedButton(
                      onPressed: () {
                        // Add your login logic here
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 130, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Color.fromRGBO(22, 22, 22, 100),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 5), // Add spacing between the button and the text

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center the text horizontally
                      children: [
                        Text(
                          "Don't have an account?",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 2), // Add spacing between the texts
                        TextButton(
                          onPressed: () {
                            // Handle navigation to sign-up screen
                            Navigator.push(context, MaterialPageRoute(builder: (context) => SignupPageWidget()));
                          },
                          child: Text(
                            "Sign up",
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              decoration: TextDecoration.underline, // Underline the text
                            ),
                          ),
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