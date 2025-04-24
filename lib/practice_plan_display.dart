import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:playiq/drill_detail_page.dart';
import 'package:playiq/practice_plan_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:playiq/home_screen.dart';

class PracticePlanDisplayPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedDrills;
  final DateTime practiceDate;

  const PracticePlanDisplayPage({
    super.key,
    required this.selectedDrills,
    required this.practiceDate,
  });

  @override
  State<PracticePlanDisplayPage> createState() =>
      _PracticePlanDisplayPageState();
}

class _PracticePlanDisplayPageState extends State<PracticePlanDisplayPage> {
  late List<Map<String, dynamic>> _drills;

  @override
  void initState() {
    super.initState();
    _drills = List<Map<String, dynamic>>.from(widget.selectedDrills);
  }

  void _markAsCompleted(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final teamId = userDoc['teamId'];

      // Delete currentPlan & practiceDate
      await FirebaseFirestore.instance.collection('teams').doc(teamId).update({
        'currentPlan': FieldValue.delete(),
        'practiceDate': FieldValue.delete(),
      });

      // Delete matching event
      final existing = await FirebaseFirestore.instance
          .collection('events')
          .where('teamId', isEqualTo: teamId)
          .where('title', isEqualTo: 'Practice Plan')
          .where('timestamp', isEqualTo: widget.practiceDate)
          .get();

      for (var doc in existing.docs) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(doc.id)
            .delete();
      }

      // Delay to let Firestore updates 
      await Future.delayed(const Duration(milliseconds: 150));

if (context.mounted) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Practice Plan Completed"),
      content: const Text("The plan has been deleted."),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // close dialog
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

    }
  }

  // Reorder drills in the list
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _drills.removeAt(oldIndex);
      _drills.insert(newIndex, item);
    });
  }

  // Delete drill from the list
  void _deleteDrill(int index) {
    setState(() {
      _drills.removeAt(index);
    });
  }

  // Swap drill with a random one from the database
  void _swapDrill(int index) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('drills').get();

    final options = snapshot.docs
        .map((doc) => Map<String, dynamic>.from(doc.data()))
        .where((d) => d['title'] != _drills[index]['title'])
        .toList();

    if (options.isEmpty) return;

    final randomDrill = (options..shuffle()).first;

    setState(() {
      _drills[index] = {
        ...randomDrill,
        "time": _drills[index]["time"],
      };
    });
  }

  // Add a custom drill to the list
  void _addCustomDrill() {
    String title = '';
    String description = '';
    String category = 'Custom';
    int? time;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Custom Drill"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Title"),
                onChanged: (val) => title = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Time (minutes)"),
                keyboardType: TextInputType.number,
                onChanged: (val) => time = int.tryParse(val),
              ),
              TextField(
                decoration:
                    const InputDecoration(labelText: "Category (optional)"),
                onChanged: (val) => category = val,
              ),
              TextField(
                decoration:
                    const InputDecoration(labelText: "Description (optional)"),
                onChanged: (val) => description = val,
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
            onPressed: () {
              if (title.isNotEmpty && time != null) {
                setState(() {
                  _drills.add({
                    'title': title,
                    'time': time,
                    'category': category,
                    'description': description,
                    'custom': true,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // Save the current plan to Firestore
  void _savePlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final teamId = userDoc['teamId'];

      await FirebaseFirestore.instance.collection('teams').doc(teamId).update({
        'currentPlan': _drills,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Practice plan saved successfully!")),
      );
    }
  }

  // Reset the practice plan
  void _resetPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final teamId = userDoc['teamId'];

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .update({'currentPlan': FieldValue.delete()});
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PracticePlanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Here's Your Practice Plan!"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              //Gray text to indicate drag and drop functionality
              child: Text(
                "Drag drills to reorder them",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ReorderableListView.builder(
                itemCount: _drills.length,
                onReorder: _onReorder,
                buildDefaultDragHandles: true,
                itemBuilder: (context, index) {
                  final drill = _drills[index];
                  final title = drill["title"] ?? "Untitled Drill";
                  final category = drill["category"] ?? "Unknown";
                  final time = drill["time"]?.toString() ?? "N/A";

                  return Card(
                    key: ValueKey('$title-$index'),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DrillDetailPage(drill: drill),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.sync_alt,
                                        color: Colors.deepPurple),
                                    onPressed: () => _swapDrill(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteDrill(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Category: $category | Time: $time min",
                            style: TextStyle(
                              color: Colors.deepPurple.shade400,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Row of buttons at the bottom of screen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add"),
                  onPressed: _addCustomDrill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text("Save"),
                  onPressed: _savePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("New"),
                  onPressed: _resetPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Complete"),
                  onPressed: () => _markAsCompleted(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
