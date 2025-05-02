import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

// Community Page
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  // Set to keep track of expanded posts
  Set<String> expandedPosts = {};

  // Sort by newest or top posts
  String sortOption = 'newest';

  // Opens the modal to create a new post
  void _openPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreatePostModal(),
    );
  }

  // Toggles the expansion of a post
  void togglePostExpansion(String postId) {
    setState(() {
      if (expandedPosts.contains(postId)) {
        expandedPosts.remove(postId);
      } else {
        expandedPosts.add(postId);
      }
    });
  }

  // Builds each post card
  Widget _buildPostCard(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    String postId = document.id;
    final currentUser = FirebaseAuth.instance.currentUser;

    int upvotes = data['upvotes'] ?? 0;
    int downvotes = data['downvotes'] ?? 0;
    Map<String, dynamic> userVotes = data['userVotes'] ?? {};

    // Check if the current user has voted on this post
    String? myVote = currentUser != null ? userVotes[currentUser.uid] : null;

    return StatefulBuilder(
      builder: (context, setState) => GestureDetector(
        onTap: () => togglePostExpansion(postId),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              border: Border.all(color: Colors.deepPurple.shade100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Post Title and expand(arrow) icon
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      expandedPosts.contains(postId)
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Post Content
                Text(
                  data['content'] ?? '',
                  maxLines: expandedPosts.contains(postId) ? null : 2,
                  overflow: expandedPosts.contains(postId)
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey[800], fontSize: 14, height: 1.4),
                ),

                const SizedBox(height: 12),

                // Category and Vote Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '#${data['category'] ?? 'General'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    // Voting buttons and counts
                    Row(
                      children: [
                        IconButton(
                          // Upvote button
                          icon: Icon(Icons.arrow_upward,
                              color: myVote == 'upvote'
                                  ? Colors.green
                                  : Colors.grey),
                          onPressed: () async {
                            if (currentUser == null) return;
                            final postRef = FirebaseFirestore.instance
                                .collection('community_posts')
                                .doc(postId);

                            if (myVote == 'upvote') {
                              // Remove upvote
                              await postRef.update({
                                'upvotes': FieldValue.increment(-1),
                                'userVotes.${currentUser.uid}':
                                    FieldValue.delete(),
                              });
                              setState(() {
                                upvotes--;
                                myVote = null;
                              });
                              // Remove downvote and switches to upvote
                            } else if (myVote == 'downvote') {
                              await postRef.update({
                                'upvotes': FieldValue.increment(1),
                                'downvotes': FieldValue.increment(-1),
                                'userVotes.${currentUser.uid}': 'upvote',
                              });
                              setState(() {
                                upvotes++;
                                downvotes--;
                                myVote = 'upvote';
                              });
                              //Add upvote
                            } else {
                              await postRef.update({
                                'upvotes': FieldValue.increment(1),
                                'userVotes.${currentUser.uid}': 'upvote',
                              });
                              setState(() {
                                upvotes++;
                                myVote = 'upvote';
                              });
                            }
                          },
                        ),
                        // AnimatedSwitcher for upvote count
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text('$upvotes',
                              key: ValueKey<int>(upvotes),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          // Remove downvote
                          icon: Icon(Icons.arrow_downward,
                              color: myVote == 'downvote'
                                  ? Colors.red
                                  : Colors.grey),
                          onPressed: () async {
                            if (currentUser == null) return;
                            final postRef = FirebaseFirestore.instance
                                .collection('community_posts')
                                .doc(postId);

                            if (myVote == 'downvote') {
                              await postRef.update({
                                'downvotes': FieldValue.increment(-1),
                                'userVotes.${currentUser.uid}':
                                    FieldValue.delete(),
                              });
                              setState(() {
                                downvotes--;
                                myVote = null;
                              });
                              // Switches from upvote to downvote
                            } else if (myVote == 'upvote') {
                              await postRef.update({
                                'upvotes': FieldValue.increment(-1),
                                'downvotes': FieldValue.increment(1),
                                'userVotes.${currentUser.uid}': 'downvote',
                              });
                              setState(() {
                                upvotes--;
                                downvotes++;
                                myVote = 'downvote';
                              });
                              // Add downvote
                            } else {
                              await postRef.update({
                                'downvotes': FieldValue.increment(1),
                                'userVotes.${currentUser.uid}': 'downvote',
                              });
                              setState(() {
                                downvotes++;
                                myVote = 'downvote';
                              });
                            }
                          },
                        ),
                        // AnimatedSwitcher for downvote count
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text('$downvotes',
                              key: ValueKey<int>(downvotes),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Timestamp
                Text(
                  data['timestamp'] != null
                      ? timeago
                          .format((data['timestamp'] as Timestamp).toDate())
                      : '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                // Comment section
                if (expandedPosts.contains(postId)) ...[
                  const Divider(height: 30),
                  CommentSection(postId: postId),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Community",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          // Sort Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "Sort by: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: sortOption,
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('New')),
                    DropdownMenuItem(value: 'top', child: Text('Top')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        sortOption = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          // Post List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .orderBy(sortOption == 'newest' ? 'timestamp' : 'upvotes',
                      descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No posts yet.'));
                }
                return ListView(
                  children: snapshot.data!.docs.map(_buildPostCard).toList(),
                );
              },
            ),
          ),
        ],
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
  final String postId; // Post ID to fetch comments for
  const CommentSection({super.key, required this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _username = "Anonymous";

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  // Fetches the username of the current user
  Future<void> _fetchUsername() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc['username'] ?? "Anonymous";
        });
      }
    }
  }

  // Adds a comment to the post
  Future<void> _addComment() async {
    final user = _auth.currentUser;
    if (user != null && _commentController.text.isNotEmpty) {
      await _firestore
          .collection('community_posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'author': _username,
        'content': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Comment List
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
                  leading: CircleAvatar(child: Text(comment['author'][0])),
                  title: Text(comment['author'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(comment['content']),
                );
              }).toList(),
            );
          },
        ),
        // Comment Input Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        )
      ],
    );
  }
}

// modal for creating a new community post
class CreatePostModal extends StatefulWidget {
  const CreatePostModal({super.key});

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String selectedCategory = "General"; // default selected category

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title of the modal
            const Text(
              "Create a Post",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Input for post title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            // Input for post content
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Content"),
            ),
            const SizedBox(height: 10),
            // Dropdown to pick post category
            DropdownButton<String>(
              value: selectedCategory,
              onChanged: (val) => setState(() => selectedCategory = val!),
              items: ["Strategy", "Training", "General", "Game Film"]
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
            ),
            const SizedBox(height: 20),
            // post button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_titleController.text.isNotEmpty &&
                      _contentController.text.isNotEmpty) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    await FirebaseFirestore.instance
                        .collection('community_posts')
                        .add({
                      'title': _titleController.text,
                      'content': _contentController.text,
                      'category': selectedCategory,
                      'author': user.displayName ?? "Anonymous",
                      'timestamp': FieldValue.serverTimestamp(),
                      'upvotes': 0,
                      'downvotes': 0,
                      'userVotes': {},
                    });
                    Navigator.pop(context); // Close the modal after posting
                  }
                },
                child: const Text("Post"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
