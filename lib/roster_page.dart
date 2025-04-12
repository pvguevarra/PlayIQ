import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RosterPage extends StatefulWidget {
  const RosterPage({super.key});

  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _teamId;

  @override
  void initState() {
    super.initState();
    _fetchTeamId();
    _autoAddCurrentUserToRoster();
  }

  // Fetch the team ID of the current user from Firestore
  Future<void> _fetchTeamId() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await _firestore.collection('users').doc(userId).get();
      setState(() {
        _teamId = doc['teamId'];
      });
    }
  }

  // Auto-add the current user to the roster if they are not already in it
  Future<void> _autoAddCurrentUserToRoster() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final teamId = userDoc['teamId'];
    final username = userDoc['username'];
    final role = userDoc['role'] == 'coach' ? 'Coach' : 'Player';

    final playerQuery = await _firestore
        .collection('players')
        .where('teamId', isEqualTo: teamId)
        .where('name', isEqualTo: username)
        .get();

    if (playerQuery.docs.isEmpty) {
      await _firestore.collection('players').add({
        'name': username,
        'position': role,
        'teamId': teamId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_teamId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Team Roster'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('players')
            .where('teamId', isEqualTo: _teamId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = snapshot.data!.docs;

          // Sort coach to the top
          players.sort((a, b) {
            final aRole = (a['position'] as String).toLowerCase();
            final bRole = (b['position'] as String).toLowerCase();

            if (aRole == 'coach' && bRole != 'coach') return -1;
            if (aRole != 'coach' && bRole == 'coach') return 1;
            return 0;
          });
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final data = player.data() as Map<String, dynamic>;

              // Check if the player is a coach or a player
              // and set the badge color accordingly
              final isCoach =(data['position'] as String).toLowerCase() == 'coach';
              final badgeColor = isCoach ? Colors.deepPurple : Colors.teal;

              return Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9, // 90% width
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      // Avatar with the first letter of the name
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        radius: 20,
                        child: Text(
                          data['name'].substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        data['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              data['position'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
