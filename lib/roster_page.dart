import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RosterPage extends StatefulWidget {
  const RosterPage({super.key});

  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  void _addOrEditPlayer({String? playerId}) {
    _nameController.clear();
    _positionController.clear();

    if (playerId != null) {
      _firestore.collection('players').doc(playerId).get().then((doc) {
        if (doc.exists) {
          _nameController.text = doc['name'];
          _positionController.text = doc['position'];
        }
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(playerId == null ? 'Add Player' : 'Edit Player'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Player Name'),
              ),
              TextField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _positionController.text.isNotEmpty) {
                  if (playerId == null) {
                    _firestore.collection('players').add({
                      'name': _nameController.text,
                      'position': _positionController.text,
                    });
                  } else {
                    _firestore.collection('players').doc(playerId).update({
                      'name': _nameController.text,
                      'position': _positionController.text,
                    });
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deletePlayer(String playerId) {
    _firestore.collection('players').doc(playerId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roster')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('players').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = snapshot.data!.docs;
          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final data = player.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['name']),
                  subtitle: Text('Position: ${data['position']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addOrEditPlayer(playerId: player.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePlayer(player.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditPlayer(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
