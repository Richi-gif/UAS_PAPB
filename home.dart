import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:praktikum_1/widget/game_widget.dart';
import 'package:praktikum_1/widget/navigation.dart';
import 'package:praktikum_1/views/game_detail.dart'; // Make sure you import GameDetailPage here

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List games = [];
  List shuffledGames = [];
  final PageController _pageController = PageController();

  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchGames() async {
    final url = Uri.parse(
        'https://api.rawg.io/api/games?key=2b0a2ae08e954536832a28e84709f26c');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final allGames = data['results'];

      final withImages = allGames
          .where((game) =>
              game['background_image'] != null &&
              game['background_image'].toString().isNotEmpty)
          .toList();

      withImages.shuffle();

      if (!mounted) return;
      setState(() {
        games = allGames;
        shuffledGames = withImages;
      });
    } else {
      throw Exception('Failed to load games');
    }
  }

  Future<void> openGameDetail(BuildContext context, int gameId) async {
    final url = Uri.parse(
        'https://api.rawg.io/api/games/$gameId?key=2b0a2ae08e954536832a28e84709f26c');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final gameDetail = json.decode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameDetailPage(game: gameDetail),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load game details')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // For a better visual effect with the rounded corners,
      // you might want a contrasting background for the Scaffold if your cards are white.
      // backgroundColor: Colors.grey[200], // Optional: if you want a non-white background
      body: games.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    minHeight: 60,
                    maxHeight: 60,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1b2838), Color(0xFF171a21)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Text(
                        'Game Ratings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF5F5F5),
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                // CAROUSEL SECTION ("Games Recommendations")
                SliverPersistentHeader(
                  pinned: false,
                  delegate: _SliverAppBarDelegate(
                    minHeight: 260,
                    maxHeight: 260,
                    // Ensure the child is ClipRect if the carousel itself isn't rounded
                    child: ClipRect(
                      // CORRECTED: Was ClipRRect in your provided code snippet
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          // REMOVED BORDER: This removes the "black line" which was likely the bottom border.
                          // If a top border is desired for the carousel, add it here:
                          // border: const Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                          boxShadow: const [
                            // Kept existing boxShadow
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                          // REMOVED BORDER RADIUS: Carousel is not the target for rounding
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  currentPage = index;
                                });
                              },
                              scrollDirection: Axis.horizontal,
                              itemCount: shuffledGames.length,
                              itemBuilder: (context, index) {
                                final game = shuffledGames[index];
                                final imageUrl = game['background_image'] ?? '';
                                final title = game['name'] ?? 'No title';

                                return GestureDetector(
                                  onTap: () {
                                    openGameDetail(context, game['id']);
                                  },
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        height: 250,
                                        width: double.infinity,
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Colors.grey[300],
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                    Icons.image_not_supported),
                                              ),
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black,
                                                  offset: Offset(0, 1),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              left: 10,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios),
                                color: Colors.white,
                                onPressed: () {
                                  if (currentPage > 0) {
                                    setState(() {
                                      currentPage--;
                                    });
                                    _pageController.animateToPage(
                                      currentPage,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.ease,
                                    );
                                  }
                                },
                              ),
                            ),
                            Positioned(
                              right: 10,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                color: Colors.white,
                                onPressed: () {
                                  if (currentPage < shuffledGames.length - 1) {
                                    setState(() {
                                      currentPage++;
                                    });
                                    _pageController.animateToPage(
                                      currentPage,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.ease,
                                    );
                                  }
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Games Recommendations:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(shuffledGames.length,
                                    (index) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: currentPage == index
                                          ? Colors.white
                                          : Colors.white38,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // "TOP GAMES" TITLE SECTION
                SliverToBoxAdapter(
                  child: Container(
                    // This Container creates the rounded top white surface
                    decoration: BoxDecoration(
                      color: Colors.white, // Or Theme.of(context).cardColor
                      borderRadius: const BorderRadius.only(
                        topLeft:
                            Radius.circular(20.0), // Adjust radius as needed
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    // Adjusted padding for the text to sit nicely under the rounded corners
                    padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
                    child: Text(
                      'Top Games:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                // LIST OF TOP GAMES
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = games[index];
                      // Ensure GameWidget has a white background if Scaffold bg is not white
                      return GameWidget(
                        game: game,
                        onTap: () => openGameDetail(context, game['id']),
                      );
                    },
                    childCount: games.length,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const CustomNavigationBar(selectedIndex: 0),
    );
  }
}

// Helper class for SliverPersistentHeader delegate
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight > minHeight ? maxHeight : minHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
