import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _searchUsers(String query) async {
    try {
      QuerySnapshot searchResults = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'Player')
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
        'status': 'Pending',
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
    List<Map<String, dynamic>> tasks = [];
    try {
      QuerySnapshot taskDocs = await FirebaseFirestore.instance.collection('users')
          .doc(playerId).collection('tasks').get();
      tasks = taskDocs.docs.map((doc) => {
        'taskName': doc['taskName'],
        'description': doc['description'],
        'status': doc['status'],
        'videoUrl': doc['videoUrl']
      }).toList();
    } catch (e) {
      print('Error fetching tasks: $e');
    }

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
              onPressed: () {
                FirebaseAuth.instance.signOut();
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
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              _searchUsers(textController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF450100),
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

  Widget _buildUsersTable() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(child: Text('No players found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Table(
        border: TableBorder.all(),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFF450100)),
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
                _buildActionsCell(user['id']),
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
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildActionsCell(String playerId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            _showAssignTaskDialog(playerId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF450100),
          ),
          child: const Text(
            'Assign Task',
            style: TextStyle(color: Colors.white),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _viewTasks(playerId, users.firstWhere((user) => user['id'] == playerId)['name']);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF450100),
          ),
          child: const Text(
            'View Tasks',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showAssignTaskDialog(String playerId) {
    final TextEditingController taskNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Assign Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskNameController,
                decoration: InputDecoration(hintText: 'Task Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(hintText: 'Description'),
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
}
