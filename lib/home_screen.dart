import 'package:flutter/material.dart';
import 'package:playiq/practice_plan_page.dart';
import 'package:playiq/gameplan_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color purple = Color(0xFF800080);
  Color grey = Color(0xFF808080);

  final List<Map<String, String>> upcomingEvents = [
    {'title': 'Practice', 'date': 'Monday, Feb 19', 'time': '5:00 PM'},
    {'title': 'Game vs Rivals', 'date': 'Wednesday, Feb 21', 'time': '7:00 PM'},
    {'title': 'Team Meeting', 'date': 'Friday, Feb 23', 'time': '6:00 PM'},
  ];

  final List<String> teamAnnouncements = [
    "Don't forget to bring water bottles to practice!",
    "New team jerseys arriving next week!",
    "Team dinner after the game on Friday!"
  ];

  final Map<String, String> weatherInfo = {
    "temperature": "72°F",
    "condition": "Partly Cloudy",
    "humidity": "60%",
    "wind": "5 mph NE"
  };

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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "What's coming up this week?",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -.5,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            upcomingEventsList(),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "Team Announcements",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -.5,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            teamAnnouncementsList(),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "Weather Forecast",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -.5,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            weatherWidget(),
          ],
        ),
      ),
    );
  }

  Widget headerParts() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          const Text(
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

  Widget upcomingEventsList() {
    return Column(
      children: upcomingEvents.map((event) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          child: ListTile(
            leading: Icon(Icons.event, color: purple),
            title: Text(event['title']!,
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${event['date']} at ${event['time']}"),
          ),
        );
      }).toList(),
    );
  }

  Widget teamAnnouncementsList() {
    return Column(
      children: teamAnnouncements.map((announcement) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          child: ListTile(
            leading: Icon(Icons.announcement, color: grey),
            title: Text(announcement,
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

  Widget weatherWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Icon(Icons.wb_sunny, color: Colors.orange),
          title: Text(
              "${weatherInfo["temperature"]} - ${weatherInfo["condition"]}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Text(
              "Humidity: ${weatherInfo["humidity"]} | Wind: ${weatherInfo["wind"]}",
              style: TextStyle(color: Colors.grey[700])),
        ),
      ),
    );
  }

  Widget practicePlanAndGamePlan() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PracticePlanPage()),
                );
              },
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: purple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.schedule, color: Colors.white, size: 50),
                    SizedBox(height: 10),
                    Text("Practice Plan",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GamePlanPage()),
                );
              },
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.sports, color: Colors.white, size: 50),
                    SizedBox(height: 10),
                    Text("Game Plan",
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
}
