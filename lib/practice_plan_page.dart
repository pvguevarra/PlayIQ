import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playiq/practice_plan_display.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PracticePlanPage extends StatefulWidget {
  const PracticePlanPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PracticePlanPageState createState() => _PracticePlanPageState();
}

class _PracticePlanPageState extends State<PracticePlanPage> {
  final TextEditingController practiceTimeController = TextEditingController();
  final TextEditingController drillTimeController = TextEditingController();

  String selectedCategory = "All"; // Default to all categories
  List<Map<String, dynamic>> drills = [];
  List<String> categories = ["All", "Offense", "Defense", "Footwork", "Conditioning", "Strategy"];

void fetchDrills() async {
  FirebaseFirestore.instance.collection('drills').get().then((querySnapshot) {
    setState(() {
      drills = querySnapshot.docs.map((doc) => doc.data()).toList();
    });
    if (kDebugMode) {
      print("Fetched drills: $drills");
    } // Debugging output
  }).catchError((error) {
    if (kDebugMode) {
      print("Error fetching drills: $error");
    } // Debugging output
  });
}

  List<Map<String, dynamic>> selectedDrills = [];

void generatePracticePlan() {
  if (drills.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No drills available. Please try again later.")),
    );
    return;
  }

  int practiceMinutes = int.tryParse(practiceTimeController.text) ?? 0;
  int drillMinutes = int.tryParse(drillTimeController.text) ?? 0;

  if (practiceMinutes == 0 || drillMinutes == 0 || drillMinutes > practiceMinutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid practice or drill time.")),
    );
    return;
  }

  List<Map<String, dynamic>> filteredDrills = selectedCategory == "All"
      ? drills
      : drills.where((drill) => drill["category"] == selectedCategory).toList();

  if (filteredDrills.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No drills found for the selected category.")),
    );
    return;
  }

  int numDrills = practiceMinutes ~/ drillMinutes;
  List<Map<String, dynamic>> selectedDrills = filteredDrills.take(numDrills).toList();

  // Navigate to the new practice plan page where it displays drills
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PracticePlanDisplayPage(selectedDrills: selectedDrills),
    ),
  );
}


  @override
  void initState() {
    super.initState();
    fetchDrills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Practice Plan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedCategory,
              onChanged: (newValue) {
                setState(() {
                  selectedCategory = newValue!;
                });
              },
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),
            TextField(
              controller: practiceTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Total Practice Duration (minutes)"),
            ),
            TextField(
              controller: drillTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Time Per Drill (minutes)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: generatePracticePlan,
              child: const Text("Generate Practice Plan"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: selectedDrills.length,
                itemBuilder: (context, index) {
                  String videoId = YoutubePlayer.convertUrlToId(selectedDrills[index]["url"]!)!;
                  return Card(
                    child: Column(
                      children: [
                        ListTile(title: Text(selectedDrills[index]["title"]!)),
                        YoutubePlayer(
                          controller: YoutubePlayerController(
                            initialVideoId: videoId,
                            flags: const YoutubePlayerFlags(autoPlay: false),
                          ),
                          showVideoProgressIndicator: true,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
