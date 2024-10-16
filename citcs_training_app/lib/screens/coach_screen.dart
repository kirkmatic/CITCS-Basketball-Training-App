import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart'; // Import the video player package

class CoachesPageWidget extends StatefulWidget {
  const CoachesPageWidget({super.key});

  @override
  State<CoachesPageWidget> createState() => _CoachesPageWidgetState();
}

class _CoachesPageWidgetState extends State<CoachesPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String coachName = "Loading...";
  List<Map<String, dynamic>> users = [];
  final TextEditingController textController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoachData();
    _fetchUsersData();
  }

  Future<void> _fetchCoachData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot coachDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (coachDoc.exists && coachDoc['name'] != null) {
          setState(() {
            coachName = coachDoc['name'];
          });
        } else {
          print('No coach data found');
        }
      } else {
        print('User not logged in');
      }
    } catch (e) {
      print('Error fetching coach name: $e');
    }
  }

  Future<void> _fetchUsersData() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot userDocs = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'Player')
          .get();
      setState(() {
        users = userDocs.docs.map((doc) => {
          'name': doc['name'],
          'student_number': doc['studentNumber'],
          'id': doc.id,
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

Future<void> _viewTasks(String playerId, String playerName) async {
    List<Map<String, dynamic>> tasks = [];
    try {
      QuerySnapshot taskDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .collection('tasks')
          .get();
      tasks = taskDocs.docs.map((doc) => {
        'taskName': doc['taskName'],
        'description': doc['description'],
        'status': doc['status'],
        'videoUrl': doc['videoUrl']
      }).toList();
    } catch (e) {
      print('Error fetching tasks: $e');
    }

    // Show the tasks in a dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tasks for $playerName'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              children: tasks.isEmpty
                  ? [Text('No tasks assigned')]
                  : tasks.map((task) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['taskName'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text('Description: ${task['description']}'),
                                Text('Status: ${task['status']}'),
                                const SizedBox(height: 8),
                                if (task['videoUrl'] != null &&
                                    task['videoUrl'].isNotEmpty)
                                  VideoPlayerWidget(videoUrl: task['videoUrl']),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
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
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchSection(),
                _buildUsersTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );
}

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 60,
      color: const Color(0xFF450100),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              coachName,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {
                _showLogoutConfirmationDialog(context);
              },
              child: Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: textController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search Player',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (query) {
                _searchUsers(query); // Call search on text change
              },
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              _searchUsers(textController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF450100),  // Updated button color
            ),
            child: const Text(
              'Search',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot userDocs = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'Player')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff') // Ensures that all names starting with the query are returned
          .get();

      setState(() {
        users = userDocs.docs.map((doc) => {
          'name': doc['name'],
          'student_number': doc['studentNumber'],
          'id': doc.id,
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildUsersTable() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Student Number')),
              DataColumn(label: Text('Actions')),
            ],
            rows: users.map((user) {
              return DataRow(cells: [
                DataCell(Text(user['name'])),
                DataCell(Text(user['student_number'])),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.task),
                        onPressed: () {
                          _assignTaskDialog(user['id']);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye),
                        onPressed: () {
                          _viewTasks(user['id'], user['name']);
                        },
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          );
  }

  Future<void> _assignTaskDialog(String playerId) async {
    final TextEditingController taskNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskNameController,
                decoration: const InputDecoration(hintText: 'Task Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Add your Firestore logic to assign the task
                await FirebaseFirestore.instance.collection('users').doc(playerId).collection('tasks').add({
                  'taskName': taskNameController.text,
                  'description': descriptionController.text,
                  'status': 'Assigned', // Default status
                  'videoUrl': '' // Add the video URL if needed
                });
                Navigator.of(context).pop();
                _fetchUsersData(); // Refresh the user list
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }
}


// Video Player Display Widget
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false; // Track play/pause state

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {}); // Update the UI when the controller is initialized
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _isPlaying = !_isPlaying; // Toggle play state
    });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: _togglePlayback, // Play/Pause on tap
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  _isPlaying
                      ? Container() // Empty container when playing
                      : Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 64.0, // Adjust size as needed
                        ), // Show play icon when paused
                ],
              ),
            ),
          )
        : Container(); // Show an empty container until the video is initialized
  }
}
