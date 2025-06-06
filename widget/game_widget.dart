import 'package:flutter/material.dart';
import 'package:praktikum_1/views/game_detail.dart';

class GameWidget extends StatelessWidget {
  final Map game;
  final VoidCallback? onTap; // <-- New optional onTap callback

  const GameWidget({required this.game, this.onTap});

  String getCategory() {
    if (game['genres'] == null || game['genres'].isEmpty) return 'N/A';
    return (game['genres'] as List).map((g) => g['name']).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            // fallback if no onTap provided (optional)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameDetailPage(game: game),
              ),
            );
          },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                game['background_image'] ?? '',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game['name'] ?? 'Untitled',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text("Category: ${getCategory()}"),
                  const SizedBox(height: 4),
                  Text("Rating: ${game['rating'] ?? 'N/A'}"),
                  const SizedBox(height: 4),
                  Text(
                      "Status: ${game['released'] != null ? 'Released' : 'Upcoming'}"),
                  const SizedBox(height: 4),
                  Text("Score: ${game['metacritic'] ?? 'N/A'}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
