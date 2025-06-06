// 📁 game_search_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GameSearchPage extends StatefulWidget {
  const GameSearchPage({super.key});

  @override
  _GameSearchPageState createState() => _GameSearchPageState();
}

class _GameSearchPageState extends State<GameSearchPage> {
  List<dynamic> games = [];
  final searchController = TextEditingController();
  bool isLoading = false;

  // It's good practice to cancel any ongoing operations in dispose
  // For http, you might use a client that can be closed, or manage a flag.
  // For simplicity here, we'll rely on the 'mounted' check.

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchGames(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        // Check mounted before setState
        setState(() {
          games = [];
          isLoading = false;
        });
      }
      return;
    }

    // Check if the widget is still mounted before initiating the loading state and API call
    if (!mounted) return;
    setState(() => isLoading = true);

    // IMPORTANT: Replace with your actual API key. Consider storing it securely.
    const String apiKey = '2b0a2ae08e954536832a28e84709f26c';
    final url =
        Uri.parse('https://api.rawg.io/api/games?key=$apiKey&search=$query');

    try {
      final response = await http.get(url);

      // After the await, check if the widget is still mounted before calling setState
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // This was the problematic line (approx. line 28 in original)
          games = data['results'] ?? []; // Handle if 'results' is null
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        // Optionally, show a message to the user
        if (mounted) {
          // Check mounted before using context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to load games: ${response.statusCode}')),
          );
        }
        print('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors during the HTTP request (e.g., network issues)
      if (!mounted) return;
      setState(() => isLoading = false);
      if (mounted) {
        // Check mounted before using context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching games: $e')),
        );
      }
      print('Error during searchGames: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Game')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged:
                  searchGames, // Consider debouncing this for better performance
              decoration: InputDecoration(
                hintText: 'Search for a game...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              autofocus: true, // Optional: for immediate typing
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (games.isEmpty && searchController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text("No games found for your search.")),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return Card(
                      // Wrap ListTile in a Card for better UI
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: game['background_image'] != null
                            ? ClipRRect(
                                // Rounded corners for the image
                                borderRadius: BorderRadius.circular(4.0),
                                child: Image.network(
                                  game['background_image'],
                                  width: 60, // Increased size slightly
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 40),
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                        width: 60,
                                        height: 60,
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)));
                                  },
                                ),
                              )
                            : const SizedBox(
                                width: 60,
                                height: 60,
                                child:
                                    Icon(Icons.image_not_supported, size: 40)),
                        title:
                            Text(game['name'] ?? 'No Name'), // Handle null name
                        onTap: () {
                          // Ensure game['id'] is not null before trying to convert
                          final gameId = game['id']?.toString();
                          if (gameId != null) {
                            Navigator.pop(context, {
                              'id': gameId,
                              'name': game['name'] ?? 'Unknown Game',
                              'coverUrl': game['background_image'] ?? ''
                            });
                          } else {
                            // Handle case where game id is null, maybe show a message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Cannot select game: Missing ID')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
