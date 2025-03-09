import 'package:flutter/material.dart';
import 'drill_detail_page.dart'; 

class PracticePlanDisplayPage extends StatelessWidget {
  final List<Map<String, dynamic>> selectedDrills;

  const PracticePlanDisplayPage({super.key, required this.selectedDrills});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Here's Your Practice Plan!")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: selectedDrills.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DrillDetailPage(drill: selectedDrills[index]),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(selectedDrills[index]["title"] ?? "Unknown"),
                  subtitle: Text(
                    "Category: ${selectedDrills[index]["category"] ?? "N/A"}, Time: ${selectedDrills[index]["time"] ?? "N/A"} mins",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
