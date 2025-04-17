import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playiq/practice_plan_display.dart';

class PracticePlanPage extends StatefulWidget {
  const PracticePlanPage({super.key});

  @override
  _PracticePlanPageState createState() => _PracticePlanPageState();
}

class _PracticePlanPageState extends State<PracticePlanPage> {
  // Dropdown selections
  String? selectedPracticeTime;
  String? selectedDrillTime;
  String selectedCategory = "All"; // Default to all categories
  String selectedSkillLevel = 'Beginner';

  // Dropdown options
  final List<String> practiceTimes = ['30', '45', '60', '75', '90'];
  final List<String> drillTimes = ['5', '10', '15', '20'];
  final List<String> categories = ["All", "Offense", "Defense", "Footwork", "Conditioning", "Strategy"];
  final List<String> skillLevels = ['Beginner', 'Intermediate', 'Advanced'];

  // Checkbox selections
  Map<String, bool> focusAreas = {
    'Speed': false,
    'Agility': false,
    'Defense': false,
    'Passing': false,
    'Conditioning': false,
    'Teamwork': false,
  };

  List<Map<String, dynamic>> drills = [];
  List<Map<String, dynamic>> selectedDrills = [];

  // Fetch drills from Firestore
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

  // Generate practice plan logic
void generatePracticePlan() {
  if (drills.isEmpty || selectedPracticeTime == null || selectedDrillTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill out all fields and ensure drills are loaded.")),
    );
    return;
  }

  int practiceMinutes = int.tryParse(selectedPracticeTime!) ?? 0;
  int drillMinutes = int.tryParse(selectedDrillTime!) ?? 0;

  if (practiceMinutes == 0 || drillMinutes == 0 || drillMinutes > practiceMinutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid practice or drill time.")),
    );
    return;
  }

  // Filter drills by category
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

  // Override drill time with user selection
  List<Map<String, dynamic>> selectedDrills = filteredDrills
      .take(numDrills)
      .map((drill) => {
            ...drill,
            "time": drillMinutes,
          })
      .toList();

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Practice Plan"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown for total practice time
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Total Practice Duration (minutes)'),
                value: selectedPracticeTime,
                items: practiceTimes.map((time) => DropdownMenuItem(
                  value: time,
                  child: Text('$time minutes'),
                )).toList(),
                onChanged: (value) => setState(() => selectedPracticeTime = value),
              ),
              const SizedBox(height: 12),

              // Dropdown for drill duration
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Time Per Drill (minutes)'),
                value: selectedDrillTime,
                items: drillTimes.map((time) => DropdownMenuItem(
                  value: time,
                  child: Text('$time minutes'),
                )).toList(),
                onChanged: (value) => setState(() => selectedDrillTime = value),
              ),
              const SizedBox(height: 12),

              // Category selector
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                value: selectedCategory,
                items: categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) => setState(() => selectedCategory = value!),
              ),
              const SizedBox(height: 12),

              // Skill level dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Skill Level'),
                value: selectedSkillLevel,
                items: skillLevels.map((level) => DropdownMenuItem(
                  value: level,
                  child: Text(level),
                )).toList(),
                onChanged: (value) => setState(() => selectedSkillLevel = value!),
              ),
              const SizedBox(height: 12),

              // Focus areas
              const Text('Focus Areas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ...focusAreas.keys.map((area) => CheckboxListTile(
                title: Text(area),
                value: focusAreas[area],
                activeColor: Colors.deepPurple,
                onChanged: (value) {
                  setState(() {
                    focusAreas[area] = value!;
                  });
                },
              )),

              const SizedBox(height: 20),

              // Generate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: generatePracticePlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Generate Practice Plan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
