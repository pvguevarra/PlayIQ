import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DrillDetailPage extends StatelessWidget {
  final Map<String, dynamic> drill;

  const DrillDetailPage({super.key, required this.drill});

  @override
  Widget build(BuildContext context) {
    String? videoId = YoutubePlayer.convertUrlToId(drill["url"] ?? "");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Drill Details"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Embedded YouTube Video
            if (videoId != null)
              YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: videoId,
                  flags: const YoutubePlayerFlags(autoPlay: false),
                ),
                showVideoProgressIndicator: true,
              ),
            const SizedBox(height: 20),

            // Title
            Text(
              drill["title"] ?? "No Title",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Category + Time
            Row(
              children: [
                Icon(Icons.category, size: 18, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Text(
                  drill["category"] ?? "Unknown",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 18, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Text(
                  "${drill["time"] ?? "N/A"} min",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Equipment Section
            const Text(
              "Equipment Needed",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Text(
              drill["equipment"] ?? "No equipment required.",
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Description Section
            const Text(
              "Drill Description",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            Text(
              drill["description"] ?? "No description available.",
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
