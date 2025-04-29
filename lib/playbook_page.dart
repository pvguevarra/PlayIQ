import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playiq/models/current_user.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:playiq/play_detail_page.dart';

class PlaybookPage extends StatefulWidget {
  const PlaybookPage({super.key});

  @override
  State<PlaybookPage> createState() => _PlaybookPageState();
}

class _PlaybookPageState extends State<PlaybookPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _openUploadPlayModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const UploadPlayModal(),
    );

    setState(() {});
  }

  Widget _buildPlayCard(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          data['title'] ?? 'Untitled Play',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              data['description'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "#${data['category'] ?? 'General'}",
              style: const TextStyle(color: Colors.deepPurple),
            ),
          ],
        ),
        leading: data['imageUrl'] != null
            ? Image.network(
                data['imageUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.sports_football,
                size: 40, color: Colors.deepPurple),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayDetailPage(
                play: {
                  ...data,
                  'docId': document.id,
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final String? teamId = CurrentUser().teamId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Playbook"),
        centerTitle: true,
      ),
      body: teamId == null
          ? const Center(child: Text("No team selected. Please re-login."))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('playbook_plays')
                  .where('teamId', isEqualTo: teamId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No plays uploaded yet.\nTap + to add your first play!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Filter out documents with null timestamps
                final validDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['timestamp'] != null;
                }).toList();

                // Sort manually by timestamp (newest first)
                validDocs.sort((a, b) {
                  final aTs = (a['timestamp'] as Timestamp).toDate();
                  final bTs = (b['timestamp'] as Timestamp).toDate();
                  return bTs.compareTo(aTs);
                });

                return ListView(
                  children:
                      validDocs.map((doc) => _buildPlayCard(doc)).toList(),
                );
              },
            ),
      floatingActionButton: CurrentUser().role == 'coach'
          ? FloatingActionButton(
              onPressed: _openUploadPlayModal,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class UploadPlayModal extends StatefulWidget {
  const UploadPlayModal({super.key});

  @override
  State<UploadPlayModal> createState() => _UploadPlayModalState();
}

class _UploadPlayModalState extends State<UploadPlayModal> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedCategory = "Offense";
  List<String> categories = ["Offense", "Defense", "Special Teams"];

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Upload New Play",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 12),
            Text("Play Diagram (optional)",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : const Center(child: Text("Tap to select an image")),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                final teamId = CurrentUser().teamId;
                if (user != null && teamId != null) {
                  String? imageUrl;

                  if (_selectedImage != null) {
                    final fileName =
                        '${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final storageRef = FirebaseStorage.instance
                        .ref()
                        .child('playbook_plays/$teamId/$fileName');
                    await storageRef.putFile(_selectedImage!);
                    imageUrl = await storageRef.getDownloadURL();
                  }

                  await FirebaseFirestore.instance
                      .collection('playbook_plays')
                      .add({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'category': selectedCategory,
                    'teamId': teamId,
                    'createdBy': user.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                    'imageUrl': imageUrl,
                  });

                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text("Save Play"),
            ),
          ],
        ),
      ),
    );
  }
}
