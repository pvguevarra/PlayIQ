import 'package:flutter/material.dart';
import 'package:playiq/models/current_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayDetailPage extends StatelessWidget {
  final Map<String, dynamic> play;

  const PlayDetailPage({super.key, required this.play});



  void _showEditPlayModal(BuildContext context) {
  final titleController = TextEditingController(text: play['title']);
  final descriptionController = TextEditingController(text: play['description']);
  String selectedCategory = play['category'] ?? "Offense";

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Edit Play"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: ["Offense", "Defense", "Special Teams"]
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedCategory = value;
                }
              },
              decoration: const InputDecoration(labelText: "Category"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('playbook_plays')
                .doc(play['docId']) // we'll fix this in a sec!
                .update({
              'title': titleController.text.trim(),
              'description': descriptionController.text.trim(),
              'category': selectedCategory,
            });
            Navigator.pop(context);
            Navigator.pop(context); // Close Play Detail Page to refresh list
          },
          child: const Text("Save Changes"),
        ),
      ],
    ),
  );
}

void _confirmDeletePlay(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete Play?"),
      content: const Text("Are you sure you want to delete this play?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('playbook_plays')
                .doc(play['docId']) // fix this too
                .delete();
            Navigator.pop(context);
            Navigator.pop(context); // Close Play Detail Page
          },
          child: const Text("Delete"),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
appBar: AppBar(
  title: Text(play['title'] ?? 'Play Details'),
  centerTitle: true,
  actions: CurrentUser().role == 'coach'
      ? [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditPlayModal(context);
              } else if (value == 'delete') {
                _confirmDeletePlay(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit Play'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Play'),
              ),
            ],
          )
        ]
      : null,
),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Play Image
            if (play['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  play['imageUrl'],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

            // Play Title
            Text(
              play['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Play Category
            Row(
              children: [
                const Icon(Icons.category, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Text(
                  play['category'] ?? 'Uncategorized',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Play Description
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              play['description'] ?? 'No description available.',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
