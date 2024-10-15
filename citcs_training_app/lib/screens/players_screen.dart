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
  File? _selectedMobileVideo; // For mobile file handling
  Uint8List? _selectedWebVideo; // For web handling

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
Future<void> _pickVideo(String taskId) async {
  if (kIsWeb) {
    // For web platform
    final input = html.FileUploadInputElement();
    input.accept = 'video/*';
    input.click();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(files[0]);
        reader.onLoadEnd.listen((e) async {
          final bytes = reader.result as Uint8List; // Use Uint8List for web
          setState(() {
            _selectedWebVideo = bytes; // Store Uint8List for web
          });

          // Update Firestore status after video selection
          await _updateTaskStatus(taskId, 'Video Attached');
        });
      } else {
        print('No video selected');
      }
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

      // Update Firestore status after video selection
      await _updateTaskStatus(taskId, 'Video Attached');
    } else {
      print('No video selected');
    }
  }
}

// Function to update the task status in Firestore
Future<void> _updateTaskStatus(String taskId, String status) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({
      'status': status, // Update the status field
    });
    print('Task status updated to: $status');
  } catch (e) {
    print('Error updating task status: $e');
  }
}
// Function to upload video to Firebase Storage
Future<void> _uploadVideo(String taskId) async {
  // Ensure at least one video selection has been made
  if (_selectedWebVideo == null && _selectedMobileVideo == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a video to upload.')),
    );
    return; // Exit early if no video is selected
  }

  // Define the video path based on the current user ID and task ID
  final videoPath = 'videos/${FirebaseAuth.instance.currentUser!.uid}/$taskId.mp4';
  final ref = FirebaseStorage.instance.ref().child(videoPath);

  try {
    if (kIsWeb) {
      // For web platform, upload the Uint8List directly
      if (_selectedWebVideo != null) {
        await ref.putData(_selectedWebVideo!, SettableMetadata(contentType: 'video/mp4'));
      }
    } else {
      // For mobile platforms, upload the File directly
      if (_selectedMobileVideo != null) {
        await ref.putFile(_selectedMobileVideo!);
      }
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

    print('Video uploaded successfully: $videoUrl');
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

Future<void> _showConfirmationDialog(String taskId) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button to dismiss dialog
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Upload'),
        content: const Text('Are you sure you want to upload the video for this task?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: const Text('Confirm'),
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog
              await _uploadVideo(taskId); // Upload the video
              await _updateTaskStatus(taskId, 'Done'); // Update task status to "Done"
              Navigator.pushReplacementNamed(context, '/player');
            },
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
                // Show the logout confirmation dialog
                _showLogoutConfirmationDialog(context);
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

// Function to show the logout confirmation dialog
void _showLogoutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // Close the dialog without logging out
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Proceed with logout
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pop(); // Close the dialog
              Navigator.pushReplacementNamed(context, '/login'); // Navigate to login
            },
            child: const Text('Logout'),
          ),
        ],
      );
    },
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
  String taskId = task['id'];
  String taskName = task['taskName'] ?? 'Unnamed Task';
  String taskDescription = task['description'] ?? 'No description available';
  String taskStatus = task['status'] ?? 'Pending'; // Default to 'Pending' if status is null
  String? videoUrl = task['videoUrl']; // Video URL if available

  // Determine the color based on the task status with a cleaner approach
  Color statusColor = _getStatusColor(taskStatus);

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4.0)],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  taskName,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                children: [
                  // Status indicator based on task status
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      taskStatus,
                      style: const TextStyle(fontSize: 12.0, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  if (videoUrl != null && videoUrl.isNotEmpty)
                    Icon(
                      Icons.attach_file,
                      color: statusColor,
                      size: 16.0,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            taskDescription,
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Visibility(
                visible: taskStatus != 'Done',
                child: ElevatedButton.icon(
                  onPressed: () {
                    _pickVideo(taskId); // Allow video selection
                    _updateTaskStatus(taskId, 'In Progress'); // Update status to "In Progress"
                  },
                  icon: const Icon(Icons.upload, size: 16.0),
                  label: const Text('Upload Video', style: TextStyle(fontSize: 12.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Set button background to white
                    foregroundColor: statusColor, // Use status color for text
                    minimumSize: const Size(120, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: statusColor),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: taskStatus != 'Done',
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Check if a video has been selected
                    if (_selectedWebVideo != null || _selectedMobileVideo != null) {
                      _showConfirmationDialog(taskId); // Show confirmation for submission
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please upload a video first.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.send, size: 16.0),
                  label: const Text('Submit Task', style: TextStyle(fontSize: 12.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: statusColor,
                    minimumSize: const Size(120, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: statusColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
// Helper function to get status color
Color _getStatusColor(String status) {
  switch (status) {
    case 'Completed':
      return Colors.green;
    case 'In Progress':
      return Colors.orange;
    case 'Pending':
      return Colors.blue;
    case 'Video Attached':
      return Colors.purple;
    default:
      return Colors.green;
  }
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
