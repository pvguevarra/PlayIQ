import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  void _openPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreatePostModal(),
    );
  }

  Widget _buildPostCard(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    String postId = document.id;
    int upvotes = data['upvotes'] ?? 0;
    int downvotes = data['downvotes'] ?? 0;

void updateVotes(String type) async {
  DocumentReference postRef =
      FirebaseFirestore.instance.collection('community_posts').doc(postId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    DocumentSnapshot snapshot = await transaction.get(postRef);

    if (!snapshot.exists) return;

    int currentUpvotes = snapshot['upvotes'] ?? 0;
    int currentDownvotes = snapshot['downvotes'] ?? 0;

    if (type == 'upvote') {
      transaction.update(postRef, {'upvotes': currentUpvotes + 1});
    } else if (type == 'downvote') {
      transaction.update(postRef, {'downvotes': currentDownvotes + 1});
    }
  }).then((_) async {
    DocumentSnapshot updatedSnapshot = await postRef.get();
    setState(() {
      upvotes = updatedSnapshot['upvotes'];
      downvotes = updatedSnapshot['downvotes'];
    });
  }).catchError((error) {
    if (kDebugMode) {
      print("Error updating votes: $error");
    } // Debugging output
  });
}


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(data['content']),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("#${data['category']}",
                    style: const TextStyle(color: Colors.grey)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.green),
                      onPressed: () => updateVotes('upvote'),
                    ),
                    Text(upvotes.toString()),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, color: Colors.red),
                      onPressed: () => updateVotes('downvote'),
                    ),
                    Text(downvotes.toString()),
                  ],
                ),
              ],
            ),
            CommentSection(postId: document.id),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Community")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .orderBy('upvotes', descending: true) // Sorting by most upvoted
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children:
                snapshot.data!.docs.map((doc) => _buildPostCard(doc)).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openPostModal,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CommentSection extends StatefulWidget {
  final String postId;
  const CommentSection({super.key, required this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = "Anonymous"; // Default username

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

 
  void _fetchUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          username = userDoc['username']; // Set the username from Firestore
        });
      }
    }
  }


  void _addComment() async {
    if (_commentController.text.isNotEmpty) {
      await _firestore
          .collection('community_posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'author': username, // Use the fetched username
        'content': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('community_posts')
              .doc(widget.postId)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return Column(
              children: snapshot.data!.docs.map((doc) {
                Map<String, dynamic> comment =
                    doc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                      child:
                          Text(comment['author'][0])), // First letter of name
                  title: Text(comment['author'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(comment['content']),
                );
              }).toList(),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: "Write a comment...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.deepPurple),
                onPressed: _addComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CreatePostModal extends StatefulWidget {
  const CreatePostModal({super.key});

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final TextEditingController _postTitleController = TextEditingController();
  final TextEditingController _postContentController = TextEditingController();
  String selectedCategory = "General";
  List<String> categories = ["Strategy", "Training", "General", "Game Film"];

  void _createPost() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Ensure user is logged in

    if (_postTitleController.text.isNotEmpty &&
        _postContentController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('community_posts').add({
        'title': _postTitleController.text,
        'content': _postContentController.text,
        'category': selectedCategory,
        'author': user.displayName ?? "Anonymous",
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': 0,
        //'reactions': {'🔥': 0, '🎯': 0, '🏆': 0},
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 350,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Create a Post",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
                controller: _postTitleController,
                decoration: const InputDecoration(labelText: "Title")),
            TextField(
                controller: _postContentController,
                decoration: const InputDecoration(labelText: "Content")),
            DropdownButton<String>(
              value: selectedCategory,
              onChanged: (value) => setState(() => selectedCategory = value!),
              items: categories
                  .map((category) =>
                      DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _createPost, child: const Text("Post")),
          ],
        ),
      ),
    );
  }
}
