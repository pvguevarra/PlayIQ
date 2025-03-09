import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DrillDetailPage extends StatelessWidget {
  final Map<String, dynamic> drill;

  const DrillDetailPage({super.key, required this.drill});

  @override
  Widget build(BuildContext context) {
    String? videoId = YoutubePlayer.convertUrlToId(drill["url"] ?? "");

    return Scaffold(
      appBar: AppBar(title: Text(drill["title"] ?? "Drill Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drill["title"] ?? "No Title",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Category: ${drill["category"] ?? "Unknown"}"),
            Text("Time: ${drill["time"] ?? "Unknown"} mins"),
            const SizedBox(height: 20),
            if (videoId != null)
              YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: videoId,
                  flags: const YoutubePlayerFlags(autoPlay: false),
                ),
                showVideoProgressIndicator: true,
              ),
          ],
        ),
      ),
    );
  }
}
