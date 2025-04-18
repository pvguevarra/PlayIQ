import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playiq/practice_plan_page.dart';
import 'package:playiq/gameplan_page.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:playiq/models/current_user.dart';
import 'package:playiq/practice_plan_display.dart';


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
      final savedPlan = List<Map<String, dynamic>>.from(teamDoc['currentPlan']);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PracticePlanDisplayPage(selectedDrills: savedPlan),
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color purple = const Color(0xFF800080);
  Color grey = const Color(0xFF808080);

  final String _apiKey = "e55f958eae154f0085471252252702";
  Map<String, dynamic> _weatherInfo = {};

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

// Requests permissions and fetches weather data from WeatherAPI
  Future<void> fetchWeather() async {
    try {
      if (kDebugMode) {
        print("Starting fetchWeather()...");
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        if (kDebugMode) {
          print("Location services are disabled.");
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (kDebugMode) {
            print("Location permission denied.");
          }
          return;
        }
      }

      if (kDebugMode) {
        print("Location services enabled & permissions granted.");
      }

      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.best,
      );
      if (kDebugMode) {
        print(
            "📍 Latitude: ${position.latitude}, Longitude: ${position.longitude}");
      }

      // Gets coordinates from emulators location
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty || placemarks[0].locality == null) {
        if (kDebugMode) {
          print("No city found! Using default location.");
        }
        return;
      }

      String city = placemarks[0].locality!;
      if (kDebugMode) {
        print("Detected City: $city");
      }

      final String url =
          "https://api.weatherapi.com/v1/current.json?key=$_apiKey&q=$city&aqi=no";
      if (kDebugMode) {
        print("Fetching weather data from: $url");
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        setState(() {
          _weatherInfo = weatherData;
        });
        if (kDebugMode) {
          print("Weather Data Retrieved Successfully!");
        }
      } else {
        if (kDebugMode) {
          print("Weather API error: Status Code ${response.statusCode}");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("ERROR in fetchWeather(): $error");
      }
    }
  }

  void _addNewEvent() {
    final titleController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();

    if (CurrentUser().role != 'coach')
      return; //Safeguard so players can't trigger it

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date'),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time'),
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
                    dateController.text.isNotEmpty &&
                    timeController.text.isNotEmpty) {
                  final user = FirebaseAuth.instance.currentUser;
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .get();
                  final teamId = userDoc['teamId'];

                  await FirebaseFirestore.instance.collection('events').add({
                    'title': titleController.text,
                    'date': dateController.text,
                    'time': timeController.text,
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

  void _addNewAnnouncement() {
    final announcementController = TextEditingController();
    if (CurrentUser().role != 'coach')
      return; //Safeguard so players can't trigger it

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

  Widget upcomingEventsList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final teamId = snapshot.data!['teamId'];
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where('teamId', isEqualTo: teamId)
              .snapshots(),
          builder: (context, eventSnapshot) {
            if (!eventSnapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final events = eventSnapshot.data!.docs;
            return Column(
              children: events.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  child: ListTile(
                    leading: Icon(Icons.event, color: purple),
                    title: Text(data['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${data['date']} at ${data['time']}"),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

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
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    child: ListTile(
                      leading: Icon(Icons.announcement, color: grey),
                      title: Text(text,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget weatherWidget() {
    if (_weatherInfo.isEmpty)
      return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Image.network(
              "https:${_weatherInfo["current"]["condition"]["icon"]}",
              width: 50,
              height: 50),
          title: Text(
            "${_weatherInfo["current"]["temp_f"]}°F - ${_weatherInfo["current"]["condition"]["text"]}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            "Humidity: ${_weatherInfo["current"]["humidity"]}% | Wind: ${_weatherInfo["current"]["wind_mph"]} mph",
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget practicePlanAndGamePlan() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
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
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamePlanPage()),
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
                    const Icon(Icons.sports, color: Colors.white, size: 50),
                    const SizedBox(height: 10),
                    const Text("Game Plan",
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
                  Text(
                    teamName,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
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
    print('Current User Role: ${CurrentUser().role}');
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
