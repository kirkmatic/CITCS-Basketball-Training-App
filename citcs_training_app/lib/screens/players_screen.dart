import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
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
  bool _isRefreshing = false; // Define _isRefreshing

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
            return {
              'id': doc.id, // Include the task ID
              ...taskData, // Include other task data
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
      if (kIsWeb && _selectedWebVideo != null) {
        // Upload the Uint8List for web
        await ref.putData(_selectedWebVideo!, SettableMetadata(contentType: 'video/mp4'));
      } else if (_selectedMobileVideo != null) {
        // Upload the File for mobile
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

      print('Video uploaded successfully: $videoUrl');
      
      // Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully!')),
      );

      // Delay for 2 seconds before showing the next SnackBar
      await Future.delayed(const Duration(seconds: 2));

      // Show the second SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please reload your page.')),
      );
    } catch (e) {
      print('Error uploading video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading video. Please try again.')),
      );
    }
  }

  // Function to show confirmation dialog
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
                
                // Show loading indicator while performing upload and update
                setState(() {
                  _isRefreshing = true;
                });

                await _uploadVideo(taskId); // Upload the video
                await _updateTaskStatus(taskId, 'Done'); // Update task status to "Done"

                // Refresh task list after completion
                await _refreshTaskList();

                setState(() {
                  _isRefreshing = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Function to handle the refresh action
  Future<void> _refreshTaskList() async {
    setState(() {
      _isRefreshing = true;
    });

    // Add any logic to refresh the task list (e.g., re-fetch from Firestore)
    await Future.delayed(const Duration(seconds: 2)); // Simulate fetching tasks

    setState(() {
      _isRefreshing = false;
    });
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Text(
        playerName,
        style: GoogleFonts.roboto(
          color: whiteColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        "Your Tasks",
        style: GoogleFonts.roboto(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    return Expanded(
      child: _isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskCard(task);
              },
            ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(task['name'] ?? 'No Task Name'),
        subtitle: Text('Status: ${task['status'] ?? 'Unknown'}'),
        trailing: ElevatedButton(
          onPressed: () => _showConfirmationDialog(task['id']),
          child: const Text('Submit Video'),
        ),
      ),
    );
  }
}
