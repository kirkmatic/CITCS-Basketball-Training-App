import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:google_fonts/google_fonts.dart';
import 'package:citcs_training_app/screens/login_screen.dart'; // Import for LoginPageWidget
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class SignupPageWidget extends StatefulWidget {
  const SignupPageWidget({super.key});

  @override
  State<SignupPageWidget> createState() => _SignupPageWidgetState();
}

class _SignupPageWidgetState extends State<SignupPageWidget> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final studentNumberController = TextEditingController();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  
  // Role selection variable
  String selectedRole = '';
  
  // State variables for password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_image.png'), // Ensure this path is correct
                fit: BoxFit.cover,
              ),
            ),
          ),

          Center(
            child: Container(
              width: 352,
              height: 650, // Adjusted for additional fields
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Your Account',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Student Number (accepts only numerical values)
                    _buildNumericTextField(studentNumberController, 'Student Number'),

                    const SizedBox(height: 10),

                    // Name
                    _buildTextField(nameController, 'Name'),

                    const SizedBox(height: 10),

                    // Age and Role (Coach or Player) inline
                    _buildAgeAndRoleSelection(),

                    const SizedBox(height: 10),

                    // Email
                    _buildTextField(emailController, 'Email'),

                    const SizedBox(height: 10),

                    // Password
                    _buildPasswordField(passwordController, 'Password', _isPasswordVisible, (value) {
                      setState(() {
                        _isPasswordVisible = value;
                      });
                    }),

                    const SizedBox(height: 10),

                    // Confirm Password
                    _buildPasswordField(confirmPasswordController, 'Confirm Password', _isConfirmPasswordVisible, (value) {
                      setState(() {
                        _isConfirmPasswordVisible = value;
                      });
                    }),

                    const SizedBox(height: 10),

                    // Signup button
                    ElevatedButton(
                      onPressed: _onSignupPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color.fromRGBO(22, 22, 22, 100),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Already have an account?
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build a text field
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white), // Make input text white
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white, // Label text color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.white, // Border color when enabled
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.white, // Border color when focused
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // Method to build a numeric text field (for Age and Student Number)
  Widget _buildNumericTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number, // Numerical keyboard
      inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Accept only digits
      style: const TextStyle(color: Colors.white), // Make input text white
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white, // Label text color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.white, // Border color when enabled
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.white, // Border color when focused
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // Method to build the age and role selection
  Widget _buildAgeAndRoleSelection() {
    return Row(
      children: [
        // Age (accepts only numerical values)
        Expanded(
          child: _buildNumericTextField(ageController, 'Age'),
        ),
        const SizedBox(width: 20), // Space between Age and Role

        // Role selection with ChoiceChips
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Role',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8), // Space between label and chips
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        'Coach',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selectedRole == 'Coach' ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: selectedRole == 'Coach',
                      onSelected: (isSelected) {
                        setState(() {
                          selectedRole = isSelected ? 'Coach' : '';
                        });
                      },
                      selectedColor: const Color.fromRGBO(22, 22, 22, 100),
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(width: 10), // Space between chips
                  Expanded(
                    child: ChoiceChip(
                      label: Text(
                        'Player',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selectedRole == 'Player' ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: selectedRole == 'Player',
                      onSelected: (isSelected) {
                        setState(() {
                          selectedRole = isSelected ? 'Player' : '';
                        });
                      },
                      selectedColor: const Color.fromRGBO(22, 22, 22, 100),
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
              if (selectedRole.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please select a role',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Method to build a password field with visibility toggle
  Widget _buildPasswordField(TextEditingController controller, String label, bool isVisible, Function(bool) onToggle) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible, // Toggle visibility
      style: const TextStyle(color: Colors.white), // Make input text white
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white, // Label text color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.white, // Border color when enabled
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.white, // Border color when focused
            width: 1.5,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: () {
            onToggle(!isVisible); // Toggle password visibility
          },
        ),
      ),
    );
  }

  // Signup method
  void _onSignupPressed() async {
    try {
      // Attempt to create a user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Write user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'studentNumber': studentNumberController.text.trim(),
        'name': nameController.text.trim(),
        'age': ageController.text.trim(),
        'role': selectedRole,
      });
      Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LoginPageWidget()),
              );
      debugPrint("User data added successfully!");
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // Method to build the login link
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.white),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPageWidget()),
            );
          },
          child: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
