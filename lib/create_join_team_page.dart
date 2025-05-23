import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_page.dart';
import 'package:playiq/models/current_user.dart';

class CreateJoinTeamPage extends StatefulWidget {
  const CreateJoinTeamPage({super.key});

  @override
  State<CreateJoinTeamPage> createState() => _CreateJoinTeamPageState();
}

class _CreateJoinTeamPageState extends State<CreateJoinTeamPage> {
  final TextEditingController teamNameController = TextEditingController();
  final TextEditingController joinCodeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String?
      generatedCode; //Stores randomly generated team code once it is created

  // Generates a 7 character random alphanumeric code
  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  // Generates a unique team code and checks if it already exists in Firestore
  // If it exists, it generates a new one until a unique code is found
  Future<void> _generateUniqueCode() async {
    bool isUnique = false;
    String newCode = '';

    while (!isUnique) {
      newCode = _generateRandomCode(7);
      final existing = await _firestore
          .collection('teams')
          .where('code', isEqualTo: newCode)
          .get();

      if (existing.docs.isEmpty) {
        isUnique = true;
      }
    }
    // Shows the generated code in the UI
    setState(() {
      generatedCode = newCode;
    });
  }

  // Creates a new team in Firestore with the generated code
  Future<void> _createTeam() async {
    final user = _auth.currentUser;
    final teamName = teamNameController.text.trim();

    if (teamName.isEmpty || generatedCode == null || user == null) return;

    // Saves the team data in Firestore
    final teamRef = await _firestore.collection('teams').add({
      'name': teamName,
      'code': generatedCode,
      'createdBy': user.uid,
      'members': [user.uid],
    });

    await _firestore.collection('users').doc(user.uid).update({
      'teamId': teamRef.id,
      'role': 'coach',
    });

    // Fetch username
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final username = userDoc['username'];

    // Auto-add coach to players
    await _firestore.collection('players').add({
      'name': username,
      'position': 'Coach',
      'teamId': teamRef.id,
    });

    // Updates singleton
    final currentUser = CurrentUser();
    currentUser.role = 'coach';
    currentUser.teamId = teamRef.id;

    // Navigates to the dashboard page after creating the team
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  // Joins an existing team using the provided code
  Future<void> _joinTeam() async {
    final user = _auth.currentUser;
    final enteredCode = joinCodeController.text.trim().toUpperCase();

    if (enteredCode.isEmpty || user == null) return;

    final result = await _firestore
        .collection('teams')
        .where('code', isEqualTo: enteredCode)
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Team code not found.")),
      );
      return;
    }

    final teamDoc = result.docs.first;
    final teamId = teamDoc.id;

    // Add user to the team's members list
    await _firestore.collection('teams').doc(teamId).update({
      'members': FieldValue.arrayUnion([user.uid]),
    });

    // Updates user with the team ID
    await _firestore.collection('users').doc(user.uid).update({
      'teamId': teamId,
      'role': 'player',
    });

    // Fetch username
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final username = userDoc['username'];

    // Auto-add player to players
    await _firestore.collection('players').add({
      'name': username,
      'position': 'Player',
      'teamId': teamId,
    });
    final currentUser = CurrentUser();
    currentUser.role = 'player';
    currentUser.teamId = teamId;

    // Navigates to the dashboard page after joining the team
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  // UI portion of the code
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Join or Create a Team"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create a Team",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Input team name
              TextField(
                controller: teamNameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Button to generate a unique team code
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                onPressed: _generateUniqueCode,
                label: const Text("Generate Team Code"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Shows the generated code once it is created
              if (generatedCode != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    "Team Code: $generatedCode",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Button to create the team
              ElevatedButton(
                onPressed: generatedCode != null ? _createTeam : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Create Team"),
              ),

              const Divider(height: 40),

              const Text(
                "Join a Team",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Input team code
              TextField(
                controller: joinCodeController,
                decoration: const InputDecoration(
                  labelText: 'Enter Team Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Join existing team button
              ElevatedButton(
                onPressed: _joinTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Join Team"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
