import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart'; // Ensure you have this import to access LoginPageWidget
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachesPageWidget extends StatefulWidget {
  const CoachesPageWidget({super.key});

  @override
  State<CoachesPageWidget> createState() => _CoachesPageWidgetState();
}

class _CoachesPageWidgetState extends State<CoachesPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String coachName = "Loading..."; // Default name before fetching actual name
  List<Map<String, dynamic>> players = []; // List to hold player data
  final TextEditingController textController = TextEditingController();

  static const Color primaryColor = Color(0xFF450100);
  static const Color backgroundColor = Color(0xFFE5E5E5);
  static const Color whiteColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchCoachData();
    _fetchPlayersData();
  }

  Future<void> _fetchCoachData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot coachDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (coachDoc.exists && coachDoc['name'] != null) {
          setState(() {
            coachName = coachDoc['name']; // Fetch and set the coach's name
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

  Future<void> _fetchPlayersData() async {
    try {
      QuerySnapshot playerDocs = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'player') // Fetch players with role 'player'
          .get();
      setState(() {
        players = playerDocs.docs.map((doc) => {
          'name': doc['name'],
          'student_number': doc['student_number'],
          'id': doc.id, // Store player ID for actions
        }).toList();
      });
    } catch (e) {
      print('Error fetching players: $e');
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
          child: SingleChildScrollView( // Allows scrolling when content overflows
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevent overflow
              children: [
                _buildHeader(),
                _buildPlayersSection(),
                _buildPlayersTable(),
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
      color: primaryColor,
      child: Align(
        alignment: const AlignmentDirectional(0, 0),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(9, 0, 9, 0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                coachName,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: whiteColor,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersSection() {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      child: Align(
        alignment: const AlignmentDirectional(0, 0),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(9, 0, 9, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            children: [
              Align(
                alignment: const AlignmentDirectional(-1, 0),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 0, 12),
                  child: Text(
                    'Players',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildSearchField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: TextFormField(
            controller: textController,
            autofocus: false,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search Player',
              filled: true,
              fillColor: backgroundColor,
              prefixIcon: Icon(
                Icons.search,
                color: primaryColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            // Implement your search functionality here
          },
          child: Text('Search'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor, // Set button color to primary color
            textStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: whiteColor,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersTable() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Table(
        border: TableBorder.all(),
        children: [
          TableRow(
            decoration: BoxDecoration(color: primaryColor),
            children: [
              TableCell(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Player Name', style: GoogleFonts.montserrat(color: whiteColor, fontWeight: FontWeight.bold)),
              )),
              TableCell(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Student Number', style: GoogleFonts.montserrat(color: whiteColor, fontWeight: FontWeight.bold)),
              )),
            ],
          ),
          ...players.map((player) {
            return TableRow(
              children: [
                TableCell(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(player['name'], style: GoogleFonts.montserrat()),
                )),
                TableCell(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(player['student_number'], style: GoogleFonts.montserrat()),
                )),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
