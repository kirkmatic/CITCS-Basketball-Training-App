import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'dart:html' as html; // For web file handling
import 'dart:typed_data'; // For handling byte data
import 'package:flutter/foundation.dart' show kIsWeb;

// Function to handle video picking based on platform
Future<void> pickVideo() async {
  if (kIsWeb) {
    // Handle web-specific video picking
  } else {
    // Handle mobile-specific video picking
  }
}


class PlayersPageWidget extends StatefulWidget {
  const PlayersPageWidget({super.key});

  @override
  State<PlayersPageWidget> createState() => _PlayersPageWidgetState();
}

class _PlayersPageWidgetState extends State<PlayersPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String playerName = "Player's Name"; // Default name before fetching actual name
  List<Map<String, dynamic>> tasks = []; // Holds fetched tasks
  File? _selectedVideo; // File to hold the picked video

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
            return taskData;
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching player tasks: $e');
    }
  }

  // Pick a video from the user's device or browser
Future<void> _pickVideo() async {
  FilePickerResult? result;

  if (kIsWeb) {
    // For web platform
    final input = html.FileUploadInputElement();
    input.accept = 'video/*';
    input.click();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files!.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(files[0]);
      reader.onLoadEnd.listen((e) {
        final bytes = reader.result as Uint8List; // Use Uint8List for web
        setState(() {
          _selectedVideo = File.fromRawPath(bytes);
        });
      });
    });
  } else {
    // For mobile platforms
    result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    // Use conditional access operator to check for null
    if (result?.files.isNotEmpty == true && result?.files.single.path != null) {
      setState(() {
        _selectedVideo = File(result!.files.single.path!);
      });
    } else {
      print('No video selected');
    }
  }
}


  // Submit the task with video upload
  void _submitTask(String taskName) {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a video before submission.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit Task'),
          content: Text('Are you sure you want to submit the task: $taskName?'),
          actions: [
            TextButton(
              onPressed: () async {
                await _uploadVideo(taskName); // Upload video and update status
                setState(() {
                  _selectedVideo = null; // Clear the video after submission
                });
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Function to upload video to Firebase Storage
  Future<void> _uploadVideo(String taskName) async {
    // Get current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Upload video to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('videos/${user.uid}/$taskName.mp4');
      await storageRef.putFile(_selectedVideo!);

      // Mark the task as completed in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskName)
          .update({'status': 'Completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task submitted successfully!')),
      );
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
              _buildTasksSection(),
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
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
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
              ...tasks.map((task) {
                return _buildTaskItem(
                  task['taskName'] ?? 'Unnamed Task', // Null safety added
                  task['status'] ?? 'Pending', // Default status if null
                  task['description'] ?? 'No description available',
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(String taskName, String taskStatus, String description) {
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
        statusColor = Colors.red;
    }

    return Card(
      color: whiteColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          taskName,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              taskStatus,
              style: TextStyle(color: statusColor),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () {
                _pickVideo(); // Pick video
                // Call submit after picking to avoid premature submission
                _submitTask(taskName); // Submit the task
              },
              child: const Text('Submit Video'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContainer(String percentage, String title) {
    return Column(
      children: [
        Text(
          percentage,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.montserrat(fontSize: 14),
        ),
      ],
    );
  }
}
