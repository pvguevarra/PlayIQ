import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
            Text("Welcome Coach", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),),
            SizedBox(width: 10),
          ],
          ), 
        ),
      ],
       ),
    );
  }
}