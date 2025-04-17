import 'package:flutter/material.dart';
import 'drill_detail_page.dart';

class PracticePlanDisplayPage extends StatelessWidget {
  final List<Map<String, dynamic>> selectedDrills;

  const PracticePlanDisplayPage({super.key, required this.selectedDrills});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Here's Your Practice Plan!"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: selectedDrills.length,
          itemBuilder: (context, index) {
            final drill = selectedDrills[index];
            final title = drill["title"] ?? "Untitled Drill";
            final category = drill["category"] ?? "Unknown";
            final time = drill["time"]?.toString() ?? "N/A";

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DrillDetailPage(drill: drill),
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14.0, horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subtitle (category + time)
                        Text(
                          "Category: $category | Time: $time min",
                          style: TextStyle(
                            color: Colors.deepPurple.shade400,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
