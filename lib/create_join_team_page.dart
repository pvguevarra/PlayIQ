import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_page.dart';

class CreateJoinTeamPage extends StatefulWidget {
  const CreateJoinTeamPage({super.key});

  @override
  State<CreateJoinTeamPage> createState() => _CreateJoinTeamPageState();
}

class _CreateJoinTeamPageState extends State<CreateJoinTeamPage> {
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _teamCodeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createTeam() async {
    final user = _auth.currentUser;
    if (user == null || _teamNameController.text.trim().isEmpty) return;

    try {
      // Create team
      DocumentReference teamRef = await _firestore.collection('teams').add({
        'name': _teamNameController.text.trim(),
        'createdBy': user.uid,
        'members': [user.uid],
      });

      // Update user document with teamId
      await _firestore.collection('users').doc(user.uid).update({
        'teamId': teamRef.id,
      });

      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating team: $e')),
      );
    }
  }

  Future<void> _joinTeam() async {
    final user = _auth.currentUser;
    final teamCode = _teamCodeController.text.trim();
    if (user == null || teamCode.isEmpty) return;

    try {
      final teamDoc = await _firestore.collection('teams').doc(teamCode).get();
      if (!teamDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team not found')),
        );
        return;
      }

      // Add user to team's member list
      await _firestore.collection('teams').doc(teamCode).update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      // Update user's teamId
      await _firestore.collection('users').doc(user.uid).update({
        'teamId': teamCode,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining team: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join or Create Team')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Create a New Team',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(labelText: 'Team Name'),
            ),
            ElevatedButton(
              onPressed: _createTeam,
              child: const Text('Create Team'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Or Join an Existing Team',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _teamCodeController,
              decoration: const InputDecoration(labelText: 'Enter Team Code'),
            ),
            ElevatedButton(
              onPressed: _joinTeam,
              child: const Text('Join Team'),
            ),
          ],
        ),
      ),
    );
  }
}
