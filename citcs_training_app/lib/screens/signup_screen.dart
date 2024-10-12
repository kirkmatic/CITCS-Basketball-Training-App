import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citcs_training_app/screens/login_screen.dart'; // Correct import for LoginPageWidget

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
            decoration: BoxDecoration(
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
                    SizedBox(height: 10),

                    // Student Number
                    _buildTextField(studentNumberController, 'Student Number'),

                    SizedBox(height: 10),

                    // Name
                    _buildTextField(nameController, 'Name'),

                    SizedBox(height: 10),

                    // Age and Role (Coach or Player) inline
                    _buildAgeAndRoleSelection(),

                    SizedBox(height: 10),

                    // Email
                    _buildTextField(emailController, 'Email'),

                    SizedBox(height: 10),

                    // Password
                    _buildPasswordField(passwordController, 'Password', _isPasswordVisible, (value) {
                      setState(() {
                        _isPasswordVisible = value;
                      });
                    }),

                    SizedBox(height: 10),

                    // Confirm Password
                    _buildPasswordField(confirmPasswordController, 'Confirm Password', _isConfirmPasswordVisible, (value) {
                      setState(() {
                        _isConfirmPasswordVisible = value;
                      });
                    }),

                    SizedBox(height: 10),

                    // Signup button
                    ElevatedButton(
                      onPressed: _onSignupPressed,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Color.fromRGBO(22, 22, 22, 100),
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
                    SizedBox(height: 5),

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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Method to build the age and role selection
  Widget _buildAgeAndRoleSelection() {
    return Row(
      children: [
        // Age
        Expanded(
          child: _buildTextField(ageController, 'Age'),
        ),
        SizedBox(width: 20), // Space between Age and Role

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
              SizedBox(height: 8), // Space between label and chips
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
                      selectedColor: Color.fromRGBO(22, 22, 22, 100),
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  SizedBox(width: 10), // Space between chips
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
                      selectedColor: Color.fromRGBO(22, 22, 22, 100),
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
              if (selectedRole.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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

  // Method to handle signup button press
  void _onSignupPressed() {
    if (selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a role')),
      );
      return;
    }
    // Further signup logic here
  }

  // Method to build the login link
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 2),
        TextButton(
          onPressed: () {
            // Navigate to the login screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPageWidget()),
            );
          },
          child: Text(
            "Login",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
