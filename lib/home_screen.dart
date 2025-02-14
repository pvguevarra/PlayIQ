import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color purple = Color(0xFF800080);
  Color grey = Color(0xFF808080);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
        ],
      ),
    );
  }

  Padding practicePlanAndGamePlan() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: purple.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: Offset(-0, 10),
                  ),
                ],
                color: purple,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.add_circle,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Generate Practice Plan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        "Start creating a practice plan",
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 20),
          //Second Box
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: grey.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: Offset(-0, 10),
                  ),
                ],
                color: grey,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.add_circle,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Game Plan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        "View this weeks game plan",
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding headerParts() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Row(
            children: [
              const Text(
                "Welcome Coach",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
          SizedBox(width: 125),
          CircleAvatar(
            radius: 27,
            backgroundImage: const AssetImage('assets/images/luka.jpg'),
          ),
        ],
      ),
    );
  }
}
