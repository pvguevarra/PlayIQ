import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:playiq/practice_plan_display.dart';

class PracticePlanPage extends StatefulWidget {
  const PracticePlanPage({super.key});

  @override
  _PracticePlanPageState createState() => _PracticePlanPageState();
}

class _PracticePlanPageState extends State<PracticePlanPage> {
  String? selectedPracticeTime;
  String? selectedDrillTime;
  String selectedSkillLevel = 'Beginner';

  final List<String> practiceTimes = ['30', '45', '60', '75', '90'];
  final List<String> drillTimes = ['5', '10', '15', '20'];
  final List<String> skillLevels = ['Beginner', 'Intermediate', 'Advanced'];

  // Multi-select category filters
  Map<String, bool> categoryFilters = {
    'Offense': false,
    'Defense': false,
    'Footwork': false,
    'Conditioning': false,
    'Strategy': false,
  };

  bool selectAllCategories = false;

  List<Map<String, dynamic>> drills = [];
  List<Map<String, dynamic>> selectedDrills = [];

  // Fetch drills and saved plan
  void fetchDrills() async {
    FirebaseFirestore.instance.collection('drills').get().then((querySnapshot) {
      setState(() {
        drills = querySnapshot.docs.map((doc) => doc.data()).toList();
      });
    }).catchError((error) {
      if (kDebugMode) {
        print("Error fetching drills: $error");
      }
    });

    // Load existing saved plan
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final teamId = userDoc['teamId'];
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .get();

      if (teamDoc.exists && teamDoc.data()?['currentPlan'] != null) {
        setState(() {
          selectedDrills =
              List<Map<String, dynamic>>.from(teamDoc['currentPlan']);
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PracticePlanDisplayPage(selectedDrills: selectedDrills),
          ),
        );
      }
    }
  }

  // Generate plan and save to Firestore
  void generatePracticePlan() async {
    if (drills.isEmpty ||
        selectedPracticeTime == null ||
        selectedDrillTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Please fill out all fields and ensure drills are loaded.")),
      );
      return;
    }

    int practiceMinutes = int.tryParse(selectedPracticeTime!) ?? 0;
    int drillMinutes = int.tryParse(selectedDrillTime!) ?? 0;

    if (practiceMinutes == 0 ||
        drillMinutes == 0 ||
        drillMinutes > practiceMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid practice or drill time.")),
      );
      return;
    }

    final selectedCategories = categoryFilters.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    List<Map<String, dynamic>> filteredDrills = selectedCategories.isEmpty
        ? drills
        : drills
            .where((drill) => selectedCategories.contains(drill["category"]))
            .toList();

    if (filteredDrills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No drills found for the selected categories.")),
      );
      return;
    }

    int numDrills = practiceMinutes ~/ drillMinutes;

    List<Map<String, dynamic>> newPlan = filteredDrills
        .take(numDrills)
        .map((drill) => {
              ...drill,
              "time": drillMinutes,
            })
        .toList();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final teamId = userDoc['teamId'];

      await FirebaseFirestore.instance.collection('teams').doc(teamId).update({
        'currentPlan': newPlan,
        'generatedAt': FieldValue.serverTimestamp(),
        'generatedBy': user.uid,
      });
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PracticePlanDisplayPage(selectedDrills: newPlan),
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
              // Dropdown for practice time
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Total Practice Duration (minutes)'),
                value: selectedPracticeTime,
                items: practiceTimes
                    .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text('$time minutes'),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => selectedPracticeTime = value),
              ),
              const SizedBox(height: 12),
              // Dropdown for drill time
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Time Per Drill (minutes)'),
                value: selectedDrillTime,
                items: drillTimes
                    .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text('$time minutes'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedDrillTime = value),
              ),
              const SizedBox(height: 12),
              // Dropdown for skill level
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Skill Level'),
                value: selectedSkillLevel,
                items: skillLevels
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => selectedSkillLevel = value!),
              ),
              const SizedBox(height: 16),
              // Multi-select for categories
              const Text(
                'Categories',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              // Checkbox for "Select All"
              CheckboxListTile(
                title: const Text("Select All"),
                value: selectAllCategories,
                activeColor: Colors.deepPurple,
                onChanged: (value) {
                  setState(() {
                    selectAllCategories = value!;
                    categoryFilters.updateAll((key, _) => value);
                  });
                },
              ),
              // Checkbox for each category
              ...categoryFilters.keys.map((category) => CheckboxListTile(
                    title: Text(category),
                    value: categoryFilters[category],
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      setState(() {
                        categoryFilters[category] = value!;
                        if (categoryFilters.containsValue(false)) {
                          selectAllCategories = false;
                        } else {
                          selectAllCategories = true;
                        }
                      });
                    },
                  )),
              const SizedBox(height: 20),
              // Button to generate practice plan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: generatePracticePlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
