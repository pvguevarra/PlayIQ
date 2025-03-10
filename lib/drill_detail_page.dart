import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DrillDetailPage extends StatelessWidget {
  final Map<String, dynamic> drill;

  const DrillDetailPage({super.key, required this.drill});

  @override
  Widget build(BuildContext context) {
    String? videoId = YoutubePlayer.convertUrlToId(drill["url"] ?? "");

    return Scaffold(
      appBar: AppBar(title: const Text("Drill Details")), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Embedded Video
            if (videoId != null)
              YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: videoId,
                  flags: const YoutubePlayerFlags(autoPlay: false),
                ),
                showVideoProgressIndicator: true,
              ),
            const SizedBox(height: 20),

            // Drill Title 
            Text(
              drill["title"] ?? "No Title",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Drill Category & Time
            Text(
              "Category: ${drill["category"] ?? "Unknown"}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              "Time: ${drill["time"] ?? "Unknown"} mins",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),

            // Description
            Text(
              "Description:",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              drill["description"] ?? "No description available.",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
