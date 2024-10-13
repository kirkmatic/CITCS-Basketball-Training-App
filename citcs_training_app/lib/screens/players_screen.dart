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
  List<Map<String, dynamic>> tasks = []; // Holds fetched tasks

  static const Color primaryColor = Color(0xFF450100);
  static const Color backgroundColor = Color(0xFFE5E5E5);
  static const Color whiteColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchPlayerName();
    _fetchPlayerTasks(); // Fetch tasks on initialization
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

  // Fetch tasks assigned to the player
  Future<void> _fetchPlayerTasks() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot taskDocs = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('tasks').get();
        setState(() {
          tasks = taskDocs.docs.map((doc) {
            final taskData = doc.data() as Map<String, dynamic>;
            print('Fetched task: ${taskData['taskName']} with description: ${taskData['description']}'); // Debug print
            return taskData;
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching player tasks: $e');
    }
  }

  void _submitTask(String taskName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Submit Task'),
          content: Text('Are you sure you want to submit the task: $taskName?'),
          actions: [
            TextButton(
              onPressed: () {
                // Logic to mark the task as submitted in Firestore
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout Confirmation'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPageWidget()),
                );
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
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
                onTap: _confirmLogout, // Call the confirm logout function
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
                _buildStatusContainer('90%', 'Speed'),
                _buildStatusContainer('85%', 'Strength'),
                _buildStatusContainer('80%', 'Endurance'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    return Expanded(
      child: Container(
        width: double.infinity,
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              ...tasks.map((task) {
                return _buildTaskItem(
                  task['taskName'],
                  task['status'],
                  task['description'] ?? 'No description available', // Task description
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(String taskName, String taskStatus, String description) {
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

    return GestureDetector(
      onTap: () => _submitTask(taskName),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column( // Change to Column to show more information
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                taskName,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4), // Space between task name and description
              Text(
                description,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4), // Space between description and status
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
      ),
    );
  }

  Widget _buildStatusContainer(String percentage, String label) {
    return Container(
      width: 120,
      height: 102,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            percentage,
            style: GoogleFonts.montserrat(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: whiteColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
