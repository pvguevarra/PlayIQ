import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playiq/practice_plan_page.dart';
import 'drill_detail_page.dart';

class PracticePlanDisplayPage extends StatelessWidget {
  final List<Map<String, dynamic>> selectedDrills;

  const PracticePlanDisplayPage({super.key, required this.selectedDrills});

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
            Expanded(
              child: ListView.builder(
                itemCount: selectedDrills.length,
                itemBuilder: (context, index) {
                  final drill = selectedDrills[index];
                  final title = drill["title"] ?? "Untitled Drill";
                  final category = drill["category"] ?? "Unknown";
                  final time = drill["time"]?.toString() ?? "N/A";

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DrillDetailPage(drill: drill),
                          ),
                        );
                      },
                      child: Card(
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
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
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
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Generate New Plan Button with Firestore clearing
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Generate New Plan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
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
                      .update({
                    'currentPlan': FieldValue.delete(),
                  });
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PracticePlanPage()),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}