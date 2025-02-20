import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PracticePlanDisplayPage extends StatelessWidget {
  final List<Map<String, dynamic>> selectedDrills;

  const PracticePlanDisplayPage({super.key, required this.selectedDrills});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generated Practice Plan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: selectedDrills.length,
          itemBuilder: (context, index) {
            String? videoId = YoutubePlayer.convertUrlToId(selectedDrills[index]["url"]!);


            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  ListTile(
                    title: Text(selectedDrills[index]["title"]!),
                    subtitle: Text("Category: ${selectedDrills[index]["category"]}, Time: ${selectedDrills[index]["time"]} mins"),
                  ),
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
            );
          },
        ),
      ),
    );
  }
}
