import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playiq/playbook_page.dart';
import 'package:playiq/practice_plan_page.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:playiq/models/current_user.dart';
import 'package:playiq/practice_plan_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables to store practice date and current plan
  DateTime? practiceDate;
  Map<String, dynamic>? currentPlan;

  @override
  void initState() {
    super.initState();
    setupPracticePlanListener(); // Watches for any changes in the practice plan
    fetchWeather(); // Fetches weather data from WeatherAPI
  }

  // Opens the practice plan page
  // If a plan is already saved, it opens the display page with the saved plan
  // Otherwise, it opens the practice plan page to create a new one
  void openPracticePlanPage(BuildContext context) async {
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
        final savedPlan =
            List<Map<String, dynamic>>.from(teamDoc['currentPlan']);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PracticePlanDisplayPage(
              selectedDrills: savedPlan,
              practiceDate: practiceDate!,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PracticePlanPage()),
        );
      }
    }
  }

  // Listens for changes in the practice plan and updates the UI accordingly
  void setupPracticePlanListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final teamId = userDoc['teamId'];

      FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .snapshots()
          .listen((docSnapshot) async {
        if (!docSnapshot.exists) return;

        final data = docSnapshot.data();
        if (data == null) return;

        // Loads plan if plan and date exist and are valid
        if (data['currentPlan'] != null && data['practiceDate'] != null) {
          final plan = List<Map<String, dynamic>>.from(data['currentPlan']);
          final dateTime = (data['practiceDate'] as Timestamp).toDate();

          if (dateTime.isAfter(DateTime.now())) {
            setState(() {
              currentPlan = {'drills': plan};
              practiceDate = dateTime;
            });
            return;
          }
        }

        // Clears UI if plan is fully removed
        if (data['currentPlan'] == null && data['practiceDate'] == null) {
          setState(() {
            currentPlan = null;
            practiceDate = null;
          });
        }
      });
    }
  }

  // Opens the practice plan display page with the current plan and date
  void openPracticePlan() {
    if (currentPlan != null) {
      final drills = List<Map<String, dynamic>>.from(currentPlan!['drills']);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PracticePlanDisplayPage(
            selectedDrills: drills,
            practiceDate:
                practiceDate!, // or practiceDate! if you’re passing it from Home
          ),
        ),
      );
    }
  }

  // Colors used in the app
  Color purple = const Color(0xFF800080);
  Color grey = const Color(0xFF808080);

  final String _apiKey = "e55f958eae154f0085471252252702"; // WeatherAPI key
  Map<String, dynamic> _weatherInfo = {}; // Weather data

// Requests permissions and fetches weather data from WeatherAPI
  Future<void> fetchWeather() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty || placemarks[0].locality == null) return;

      String city = placemarks[0].locality!;

      final String url =
          "https://api.weatherapi.com/v1/current.json?key=$_apiKey&q=$city&aqi=no";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        setState(() {
          _weatherInfo = weatherData;
        });
      }
    } catch (_) {
    }
  }
  // Creates a new event in Firestore with date and time
  void _addNewEvent() {
    final titleController = TextEditingController();
    DateTime? selectedEventDateTime;

    // Only allow coaches to add events
    if (CurrentUser().role != 'coach') return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add New Event'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input field for event title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
                // Date and time picker button
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedEventDateTime != null
                        ? "${selectedEventDateTime!.month}/${selectedEventDateTime!.day} @ ${selectedEventDateTime!.hour}:${selectedEventDateTime!.minute.toString().padLeft(2, '0')}"
                        : "Select Date & Time",
                  ),
                  onPressed: () async {
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
                          selectedEventDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      selectedEventDateTime != null) {
                    final user = FirebaseAuth.instance.currentUser;
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .get();
                    final teamId = userDoc['teamId'];
                    // Add event to Firestore
                    await FirebaseFirestore.instance.collection('events').add({
                      'title': titleController.text.trim(),
                      'timestamp': selectedEventDateTime,
                      'teamId': teamId,
                    });

                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Adds a new announcement to Firestore
  void _addNewAnnouncement() {
    final announcementController = TextEditingController();

    // Only allow coaches to add announcements
    if (CurrentUser().role != 'coach') {
      return;
    } 

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Announcement'),
          content: TextField(
            controller: announcementController,
            decoration: const InputDecoration(labelText: 'Announcement'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (announcementController.text.isNotEmpty) {
                  final user = FirebaseAuth.instance.currentUser;
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .get();
                  final teamId = userDoc['teamId'];
                  // Add announcement to Firestore
                  await FirebaseFirestore.instance
                      .collection('announcements')
                      .add({
                    'text': announcementController.text,
                    'teamId': teamId,
                  });

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Displays a list of upcoming events for the team
  Widget upcomingEventsList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final teamId = snapshot.data!['teamId'];
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where('teamId', isEqualTo: teamId)
              .snapshots(),
          builder: (context, eventSnapshot) {
            if (!eventSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final events = eventSnapshot.data!.docs;
            return Column(
              children: events.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final DateTime? ts = data['timestamp'] != null
                    ? (data['timestamp'] as Timestamp).toDate()
                    : null;
                final isPracticePlan = data['title'] == 'Practice Plan';
                if (isPracticePlan) {
                  if (isPracticePlan &&
                      (practiceDate == null || currentPlan == null)) {
                    return const SizedBox.shrink(); // Skip if no plan or incomplete practice plan
                  }
                  // Don't allow swipe-to-delete for practice plans
                  return GestureDetector(
                    onTap: currentPlan != null && practiceDate != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PracticePlanDisplayPage(
                                  selectedDrills:
                                      List<Map<String, dynamic>>.from(
                                          currentPlan!['drills']),
                                  practiceDate: practiceDate!,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        border: Border.all(color: Colors.deepPurple),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: purple),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ts != null
                                    ? "${ts.month}/${ts.day} @ ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}"
                                    : "No time",
                                style: const TextStyle(
                                    fontSize: 13, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Allow swipe-to-delete for other events that are not practice plans
                  return Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      return await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete Event?"),
                          content: const Text(
                              "Are you sure you want to delete this event?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) {
                      FirebaseFirestore.instance
                          .collection('events')
                          .doc(doc.id)
                          .delete();
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        border: Border.all(color: Colors.deepPurple),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: purple),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ts != null
                                    ? "${ts.month}/${ts.day} @ ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}"
                                    : "No time",
                                style: const TextStyle(
                                    fontSize: 13, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }).toList(),
            );
          },
        );
      },
    );
  }

  // Displays a list of team announcements
  Widget teamAnnouncementsList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final teamId = snapshot.data!['teamId'];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .where('teamId', isEqualTo: teamId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final announcements = snapshot.data!.docs;
            if (announcements.isEmpty) {
              return const Center(child: Text("No announcements yet."));
            }

            return Column(
              children: announcements.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final text = data['text'] ?? '';
                return Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    return await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Announcement?"),
                        content: const Text(
                            "Are you sure you want to delete this announcement?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) {
                    FirebaseFirestore.instance
                        .collection('announcements')
                        .doc(doc.id)
                        .delete();
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      border: Border.all(color: Colors.deepPurple),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.announcement, color: purple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // Displays the weather widget with current weather information
  Widget weatherWidget() {
    if (_weatherInfo.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          // Displays the weather icon and information
          leading: Image.network(
              "https:${_weatherInfo["current"]["condition"]["icon"]}",
              width: 50,
              height: 50),
          // Displays the current temperature and condition
          title: Text(
            "${_weatherInfo["current"]["temp_f"]}°F - ${_weatherInfo["current"]["condition"]["text"]}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          // Displays humidity and wind 
          subtitle: Text(
            "Humidity: ${_weatherInfo["current"]["humidity"]}% | Wind: ${_weatherInfo["current"]["wind_mph"]} mph",
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  // Dashboard buttons for practice plan and playbook navigation
  Widget practicePlanAndGamePlan() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          // Practice Plan button
          Expanded(
            child: GestureDetector(
              onTap: () => openPracticePlanPage(context),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: purple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white, size: 50),
                    const SizedBox(height: 10),
                    const Text("Practice Plan",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Playbook button
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlaybookPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.book, color: Colors.white, size: 50),
                    const SizedBox(height: 10),
                    const Text("Playbook",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header with team name and user avatar
  Widget headerParts() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          "Team",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: CircularProgressIndicator(),
          );
        }

        final teamId = userSnapshot.data!['teamId'];
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('teams').doc(teamId).get(),
          builder: (context, teamSnapshot) {
            if (!teamSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: CircularProgressIndicator(),
              );
            }

            final teamName = teamSnapshot.data!['name'] ?? 'Team';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  // Team name
                  Text(
                    teamName,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  // User avatar with initial
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      (userSnapshot.data!['username'] as String)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debugging: Print the current user role
    // Delete later on
    if (kDebugMode) {
      print('Current User Role: ${CurrentUser().role}');
    }
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerParts(),
            const SizedBox(height: 20),
            practicePlanAndGamePlan(),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "What's coming up this week?",
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -.5,
                        color: Colors.black),
                  ),
                  if (CurrentUser().role == 'coach')
                    IconButton(
                      icon: Icon(Icons.add, color: purple),
                      onPressed: _addNewEvent,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            upcomingEventsList(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Team Announcements",
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -.5,
                        color: Colors.black),
                  ),
                  if (CurrentUser().role == 'coach')
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.deepPurple),
                      onPressed: _addNewAnnouncement,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            teamAnnouncementsList(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: const Text(
                "Weather Forecast",
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -.5,
                    color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
            weatherWidget(),
          ],
        ),
      ),
    );
  }
}
