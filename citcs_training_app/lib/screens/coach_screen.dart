import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Ensure you have this import for the login screen

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
  bool isLoading = true; // Add loading state

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
      isLoading = true; // Start loading
    });

    try {
      // Fetch only users with the role of 'Player'
      QuerySnapshot userDocs = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'Player')
          .get();
      setState(() {
        users = userDocs.docs.map((doc) => {
          'name': doc['name'],
          'student_number': doc['studentNumber'],
          'id': doc.id,
        }).toList();
        isLoading = false; // Stop loading
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        isLoading = false; // Stop loading even on error
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      QuerySnapshot searchResults = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'Player')  // Only players in the search
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      setState(() {
        users = searchResults.docs.map((doc) => {
          'name': doc['name'],
          'student_number': doc['studentNumber'],
          'id': doc.id,
        }).toList();
      });
    } catch (e) {
      print('Error searching users: $e');
    }
  }

  Future<void> _assignTask(String playerId, String taskName, String description) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(playerId).collection('tasks').add({
        'taskName': taskName,
        'description': description,
        'status': 'Pending', // Default status when assigning a new task
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task assigned successfully')),
      );
    } catch (e) {
      print('Error assigning task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign task')),
      );
    }
  }

  Future<void> _viewTasks(String playerId, String playerName) async {
    // Fetch the tasks assigned to the player
    List<Map<String, dynamic>> tasks = [];
    try {
      QuerySnapshot taskDocs = await FirebaseFirestore.instance.collection('users')
          .doc(playerId).collection('tasks').get();
      tasks = taskDocs.docs.map((doc) => {
        'taskName': doc['taskName'],
        'description': doc['description'],
        'status': doc['status'],
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
                      return ListTile(
                        title: Text(task['taskName']),
                        subtitle: Text('Description: ${task['description']}\nStatus: ${task['status']}'),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 60,
      color: const Color(0xFF450100),  // Updated color
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
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPageWidget()),
                );
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
            child: const Text(  // Changed to a text instead of an icon
              'Search',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator()); // Show loading spinner
    }

    if (users.isEmpty) {
      return Center(child: Text('No players found.')); // Show message when no users are found
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Table(
        border: TableBorder.all(),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFF450100)),  // Updated color for the table header
            children: [
              _buildTableCell('Player Name', true),
              _buildTableCell('Student Number', true),
              _buildTableCell('Actions', true),
            ],
          ),
          ...users.map((user) {
            return TableRow(
              children: [
                _buildTableCell(user['name'] ?? 'N/A', false),
                _buildTableCell(user['student_number'] ?? 'N/A', false),
                _buildActionsCell(user),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, bool isHeader) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(  // Centering the content
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: isHeader ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildActionsCell(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(  // Centering the icons and buttons
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,  // Centering the icons within the row
          children: [
            IconButton(
              icon: Icon(Icons.bar_chart, color: Colors.blue[800]),
              onPressed: () {
                _showStatsDialog(user['name']);
              },
            ),
            const SizedBox(width: 5),
            IconButton(
              icon: Icon(Icons.assignment, color: Colors.red[800]),
              onPressed: () {
                _showAssignTaskDialog(user['id'], user['name']);
              },
            ),
            const SizedBox(width: 5),
            IconButton(
              icon: Icon(Icons.task, color: Colors.green[800]),
              onPressed: () {
                _viewTasks(user['id'], user['name']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignTaskDialog(String playerId, String playerName) {
    TextEditingController taskNameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign Task to $playerName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskNameController,
                decoration: InputDecoration(hintText: 'Enter task name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(hintText: 'Enter task description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _assignTask(playerId, taskNameController.text.trim(), descriptionController.text.trim());
                Navigator.of(context).pop();
              },
              child: Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  void _showStatsDialog(String playerName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Stats for $playerName'),
          content: Text('Player stats will be shown here.'),
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
}
