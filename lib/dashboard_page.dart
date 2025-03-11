import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:playiq/home_screen.dart';
import 'package:playiq/community_page.dart'; 
import 'package:playiq/roster_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const HomeScreen(),
    Scaffold(), // Placeholder for Messages
    const RosterPage(), // Placeholder for Roster
    const CommunityPage(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.deepPurple,
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home5),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.message),
            label: "Message",
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.frame_1),
            label: "Roster",
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.people), 
            label: "Community", 
          ),
        ],
      ),
      body: pages[selectedIndex],
    );
  }
}
