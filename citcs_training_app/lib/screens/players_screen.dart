import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart'; // Ensure you have this import to access LoginPageWidget
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayersPageWidget extends StatefulWidget {
  const PlayersPageWidget({super.key});

  @override
  State<PlayersPageWidget> createState() => _PlayersPageWidgetState();
}

class _PlayersPageWidgetState extends State<PlayersPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String playerName = "Player's Name"; // Default name before fetching actual name

  static const Color primaryColor = Color(0xFF450100);
  static const Color backgroundColor = Color(0xFFE5E5E5);
  static const Color whiteColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchPlayerName();
  }

  // Fetch the player's name from Firestore
  Future<void> _fetchPlayerName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc['name'] != null) {
          setState(() {
            playerName = userDoc['name']; // Fetch and set the player's name
          });
        }
      }
    } catch (e) {
      print('Error fetching player name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: whiteColor,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              _buildHeader(),
              _buildStatusSection(),
              _buildTasksSection(), // Extend the background to the bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 60,
      color: primaryColor,
      child: Align(
        alignment: AlignmentDirectional.center,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(9, 0, 9, 0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                playerName,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: whiteColor,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to the login screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPageWidget()),
                  );
                },
                child: Text(
                  'Logout',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: whiteColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8.5, 0, 8.5, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: const AlignmentDirectional(-1, 0),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 0, 10),
                child: Text(
                  'My Status',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusContainer('90%', 'Speed'), // Changed from Dribbling to Speed
                _buildStatusContainer('85%', 'Strength'), // Changed from Passing to Strength
                _buildStatusContainer('80%', 'Endurance'), // Changed from Shooting to Endurance
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Extend this section to fill the remaining height
  Widget _buildTasksSection() {
    return Expanded( // This makes the background extend to the bottom
      child: Container(
        width: double.infinity,
        color: backgroundColor, // Set background color for the entire section
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // Adjust padding as necessary
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
            children: [
              Text(
                'Tasks',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              // Task items
              _buildTaskItem('Complete Speed Drills', 'In Progress'),
              const SizedBox(height: 8),
              _buildTaskItem('Strength Training Session', 'Completed'),
              const SizedBox(height: 8),
              _buildTaskItem('Endurance Running Session', 'Pending'),
              const SizedBox(height: 8),
              _buildTaskItem('Team Strategy Meeting', 'Not Started'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(String taskName, String taskStatus) {
    // Colors based on task status
    Color statusColor;
    switch (taskStatus) {
      case 'Completed':
        statusColor = Colors.green;
        break;
      case 'In Progress':
        statusColor = Colors.orange;
        break;
      case 'Pending':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.red; // Not Started or unknown
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 4, // To give it a slight shadow
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Task name on the left, status on the right
          children: [
            // Task name
            Text(
              taskName,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            // Task status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                taskStatus,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContainer(String percentage, String label) {
    return Container(
      width: 120, // Minimized width
      height: 102,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Align(
        alignment: const AlignmentDirectional(0, 0),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 16.5, 0, 16.5),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                percentage,
                style: GoogleFonts.montserrat(
                  color: whiteColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: whiteColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
