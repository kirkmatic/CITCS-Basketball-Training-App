import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'dart:html' as html; // For web file handling
import 'dart:typed_data'; // For handling byte data
import 'dart:io'; // For mobile file handling

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
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
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
  // Fetch tasks assigned to the player
Future<void> _fetchPlayerTasks() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot taskDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .get();
      setState(() {
        tasks = taskDocs.docs.map((doc) {
          final taskData = doc.data() as Map<String, dynamic>;
          // Add the document ID to the task data
          return {
            'id': doc.id, // Add this line to include the task ID
            ...taskData, // Spread operator to include other task data
          };
        }).toList();
      });
    }
  } catch (e) {
    debugPrint('Error fetching player tasks: $e');
  }
}


  // Pick a video from the user's device or browser
 // Pick a video from the user's device or browser
Future<void> _pickVideo() async {
  File? _selectedMobileVideo; // For mobile file handling
  Uint8List? _selectedWebVideo; // For web handling
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
          _selectedWebVideo = bytes; // Store Uint8List for web
        });
      });
    });
  } else {
    // For mobile platforms
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      setState(() {
        _selectedMobileVideo = File(result.files.single.path!); // Store mobile File
      });
    } else {
      print('No video selected');
    }
  }
}




  // Show a confirmation dialog before submitting the task
  void _showConfirmationDialog(String taskId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit Task'),
          content: const Text('Are you sure you want to submit the task?'),
          actions: [
            TextButton(
              onPressed: () async {
                await _uploadVideo(taskId); // Upload video and update status
                _clearSelectedVideo(); // Clear the video after submission
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Clear the selected video
  void _clearSelectedVideo() {
    setState(() {
      _selectedVideo = null; // Clear the video after submission
    });
  }

  // Function to upload video to Firebase Storage
// Function to upload video to Firebase Storage
// Function to upload video to Firebase Storage
Future<void> _uploadVideo(String taskId) async {
  File? _selectedMobileVideo; // For mobile file handling
Uint8List? _selectedWebVideo; // For web handling
  try {
    // Check which video has been selected based on platform
    if (_selectedWebVideo == null && _selectedMobileVideo == null) return;

    // Define the video path based on the current user ID and task ID
    final videoPath = 'videos/${FirebaseAuth.instance.currentUser!.uid}/$taskId.mp4';
    final ref = FirebaseStorage.instance.ref().child(videoPath);

    if (kIsWeb) {
      // For web platform, upload the Uint8List directly
      await ref.putData(_selectedWebVideo!, SettableMetadata(contentType: 'video/mp4'));
    } else {
      // For mobile platforms, upload the File directly
      await ref.putFile(_selectedMobileVideo!);
    }

    // Get the video URL after upload completes
    final videoUrl = await ref.getDownloadURL();

    // Update Firestore with the video URL
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({
      'videoUrl': videoUrl,
      'status': 'Video Attached', // Update status
    });

    print('Video uploaded and URL updated in Firestore.');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video uploaded successfully!')),
    );
  } catch (e) {
    print('Error uploading video: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error uploading video. Please try again.')),
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
                ),
              ),
              const SizedBox(height: 8.0),
              tasks.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return _buildTaskItem(tasks[index]);
                      },
                    )
                  : const Center(child: Text('No tasks assigned.')),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildTaskItem(Map<String, dynamic> task) {
  // Extract relevant fields from the task
  String taskId = task['id']; // Extract task ID
  String taskName = task['taskName'] ?? 'Unnamed Task';
  String taskDescription = task['description'] ?? 'No description available';
  String taskStatus = task['status'] ?? 'Pending'; // Default to 'Pending' if status is null
  String? videoUrl = task['videoUrl']; // Video URL if available
  
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
    case 'Video Attached':
      statusColor = Colors.purple; // New status color for video attached
      break;
    default:
      statusColor = Colors.red; // For unrecognized statuses
  }

  return Card(
    color: whiteColor,
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            taskName,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8.0),
          Text(
            taskDescription,
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
          const SizedBox(height: 8.0),
          if (videoUrl != null && videoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Video Attached',
                style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _pickVideo(); // Allow video selection
                },
                child: const Text('Upload Video'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_selectedVideo != null) {
                    _showConfirmationDialog(taskId); // Show confirmation for submission
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please upload a video first.')),
                    );
                  }
                },
                child: const Text('Submit Task'),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            taskStatus,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildStatusContainer(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.grey, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
