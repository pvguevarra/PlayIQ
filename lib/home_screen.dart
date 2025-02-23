import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:playiq/practice_plan_page.dart';
import 'package:playiq/gameplan_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color purple = const Color(0xFF800080);
  Color grey = const Color(0xFF808080);

  final Map<String, String> weatherInfo = {
    "temperature": "72°F",
    "condition": "Partly Cloudy",
    "humidity": "60%",
    "wind": "5 mph NE"
  };

  // Function to add a new event to Firestore
  void _addNewEvent() {
    final titleController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();

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
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    dateController.text.isNotEmpty &&
                    timeController.text.isNotEmpty) {
                  FirebaseFirestore.instance.collection('events').add({
                    'title': titleController.text,
                    'date': dateController.text,
                    'time': timeController.text,
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

  // Function to add a new announcement to Firestore
  void _addNewAnnouncement() {
    final announcementController = TextEditingController();

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
              onPressed: () {
                if (announcementController.text.isNotEmpty) {
                  FirebaseFirestore.instance.collection('announcements').add({
                    'text': announcementController.text,
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

  // StreamBuilder for Upcoming Events from Firestore
  Widget upcomingEventsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data!.docs;
        return Column(
          children: events.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final date = data['date'] ?? '';
            final time = data['time'] ?? '';
            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                FirebaseFirestore.instance.collection('events').doc(doc.id).delete();
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                child: ListTile(
                  leading: Icon(Icons.event, color: purple),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$date at $time"),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // StreamBuilder for Team Announcements from Firestore
  Widget teamAnnouncementsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final announcements = snapshot.data!.docs;
        return Column(
          children: announcements.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final text = data['text'] ?? '';
            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                FirebaseFirestore.instance.collection('announcements').doc(doc.id).delete();
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                child: ListTile(
                  leading: Icon(Icons.announcement, color: grey),
                  title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget weatherWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: const Icon(Icons.wb_sunny, color: Colors.orange),
          title: Text(
              "${weatherInfo["temperature"]} - ${weatherInfo["condition"]}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Text(
              "Humidity: ${weatherInfo["humidity"]} | Wind: ${weatherInfo["wind"]}",
              style: TextStyle(color: Colors.grey[700])),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PracticePlanPage()),
                );
              },
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: const [
          Text(
            "Welcome Coach",
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Spacer(),
          CircleAvatar(
            radius: 27,
            backgroundImage: AssetImage('assets/images/luka.jpg'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerParts(),
            const SizedBox(height: 20),
            practicePlanAndGamePlan(),
            const SizedBox(height: 30),
            // Upcoming Events Section with Add Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "What's coming up this week?",
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -.5,
                        color: Colors.black),
                  ),
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
            // Team Announcements Section with Add Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Team Announcements",
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -.5,
                        color: Colors.black),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: grey),
                    onPressed: _addNewAnnouncement,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            teamAnnouncementsList(),
            const SizedBox(height: 20),
            // Weather Forecast Section remains unchanged
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
