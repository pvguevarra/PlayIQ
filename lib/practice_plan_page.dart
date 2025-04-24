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
  DateTime? selectedDateTime;

  final List<String> practiceTimes = ['30', '45', '60', '75', '90'];
  final List<String> drillTimes = ['5', '10', '15', '20'];

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
            builder: (context) => PracticePlanDisplayPage(
              selectedDrills: selectedDrills,
              practiceDate: selectedDateTime!,
            ),
          ),
        );
      }
    }
  }

  // Pick date and time for practice
  void _pickDateTime() async {
    DateTime now = DateTime.now();
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          selectedDateTime =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  // Generate plan and save to Firestore
  void generatePracticePlan() async {
    if (drills.isEmpty ||
        selectedPracticeTime == null ||
        selectedDrillTime == null ||
        selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out all fields.")),
      );
      return;
    }

    int practiceMinutes = int.parse(selectedPracticeTime!);
    int drillMinutes = int.parse(selectedDrillTime!);
    int numDrills = practiceMinutes ~/ drillMinutes;

    final selectedCategories = categoryFilters.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    List<Map<String, dynamic>> filteredDrills = selectedCategories.isEmpty
        ? drills
        : drills
            .where((drill) => selectedCategories.contains(drill["category"]))
            .toList();

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

      // Save plan to teams collection
      await FirebaseFirestore.instance.collection('teams').doc(teamId).set({
        'currentPlan': newPlan,
        'practiceDate': selectedDateTime,
        'generatedAt': FieldValue.serverTimestamp(),
        'generatedBy': user.uid,
      }, SetOptions(merge: true));

      // Add event directly during generation

      if (selectedDateTime != null) {
        // Delete previous Practice Plan events before adding new one
        final previous = await FirebaseFirestore.instance
            .collection('events')
            .where('teamId', isEqualTo: teamId)
            .where('title', isEqualTo: 'Practice Plan')
            .get();

        for (var doc in previous.docs) {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(doc.id)
              .delete();
        }

        final existing = await FirebaseFirestore.instance
            .collection('events')
            .where('teamId', isEqualTo: teamId)
            .where('title', isEqualTo: 'Practice Plan')
            .where('timestamp', isEqualTo: selectedDateTime)
            .get();

        if (existing.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('events').add({
            'title': 'Practice Plan',
            'type': 'practice',
            'teamId': teamId,
            'timestamp': selectedDateTime,
          });
        }
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PracticePlanDisplayPage(
            selectedDrills: newPlan, practiceDate: selectedDateTime!),
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
              // Date/time picker
              TextButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  selectedDateTime != null
                      ? "Practice Date: ${selectedDateTime!.month}/${selectedDateTime!.day} @ ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}"
                      : "Select Practice Date & Time",
                  style: const TextStyle(fontSize: 16),
                ),
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
