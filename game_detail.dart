import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameDetailPage extends StatefulWidget {
  final Map game;

  const GameDetailPage({super.key, required this.game}); // Added super.key

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final CollectionReference commentsRef =
      FirebaseFirestore.instance.collection('comments');
  final user = FirebaseAuth.instance.currentUser;

  Map? detailedGame;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGameDetails();
  }

  Future<void> fetchGameDetails() async {
    final gameId = widget.game['id'];
    // Ensure API key is stored securely and not hardcoded in production
    const String apiKey = '2b0a2ae08e954536832a28e84709f26c';
    final url = Uri.parse('https://api.rawg.io/api/games/$gameId?key=$apiKey');

    try {
      final response = await http.get(url);

      if (!mounted) return; // Check if the widget is still in the tree

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          detailedGame = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          // Check mounted again before showing SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to load detailed game info: ${response.statusCode}')),
          );
        }
        print('Failed to load detailed game info: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading game details: $e')),
        );
      }
      print('Error fetching game details: $e');
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || user == null) return;

    try {
      await commentsRef.add({
        'gameId': widget.game['id'],
        'userId': user!.uid,
        'userEmail': user!
            .email, // Consider if you really need to store email with every comment
        'text': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (e) {
      print('Error submitting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to submit comment. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteComment(String docId) async {
    try {
      await commentsRef.doc(docId).delete();
    } catch (e) {
      print('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete comment. Please try again.')),
        );
      }
    }
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Chip(
      label: Text("$label: $value",
          style: const TextStyle(fontSize: 14, color: Colors.white)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: color,
      materialTapTargetSize:
          MaterialTapTargetSize.shrinkWrap, // Reduces padding
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2), // Adjust padding
    );
  }

  Color _scoreColor(dynamic scoreValue) {
    // Changed to dynamic to handle potential int or null
    if (scoreValue == null) return Colors.grey.shade700;
    if (scoreValue is String) {
      // Handle if score is unexpectedly a string
      try {
        scoreValue = int.parse(scoreValue);
      } catch (e) {
        return Colors.grey.shade700;
      }
    }
    if (scoreValue is! int)
      return Colors.grey.shade700; // Ensure it's an int after parsing

    if (scoreValue >= 75) return Colors.green.shade600;
    if (scoreValue >= 50) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final gameData = detailedGame ??
        widget.game; // Use detailedGame if available, else fallback

    return Scaffold(
      appBar: AppBar(
        title: Text(
          gameData['name'] ?? 'Game Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5F5F5),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Kept for gradient effect
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1b2838), Color(0xFF171a21)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MODIFICATION: Removed ClipRRect from here
                  if (gameData['background_image'] != null)
                    Image.network(
                      gameData['background_image'],
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 220,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.broken_image,
                            color: Colors.grey.shade600, size: 50),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 220,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameData['name'] ?? 'No title',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            if (gameData['genres'] != null &&
                                gameData['genres'] is List &&
                                (gameData['genres'] as List).isNotEmpty)
                              _buildInfoChip(
                                "Category",
                                (gameData['genres'] as List)
                                    .map((g) => g['name'])
                                    .join(', '),
                                Colors.blue.shade600,
                              ),
                            _buildInfoChip(
                              "Status",
                              gameData['released'] != null
                                  ? 'Released'
                                  : 'Upcoming',
                              Colors.grey.shade600,
                            ),
                            _buildInfoChip(
                              "Score",
                              "${gameData['metacritic'] ?? 'N/A'}",
                              _scoreColor(gameData['metacritic']),
                            ),
                            _buildInfoChip(
                              "Rating",
                              "${gameData['rating'] ?? 'N/A'}",
                              Colors.deepPurple.shade400,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          "Description",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 8),
                        if (detailedGame != null &&
                            detailedGame!['description_raw'] != null &&
                            (detailedGame!['description_raw'] as String)
                                .isNotEmpty)
                          Text(
                            // Basic clean up for description_raw
                            (detailedGame!['description_raw'] as String)
                                .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'),
                                    '') // Remove HTML tags
                                .trim(),
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Color(0xFF555555)),
                          )
                        else if (!isLoading) // Only show if not loading and description is unavailable
                          const Text("No description available.",
                              style: TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Color(0xFF555555))),
                        const SizedBox(height: 24),
                        const Divider(),
                        const Text(
                          "Comments",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333)),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: commentsRef
                              .where('gameId',
                                  isEqualTo: widget.game[
                                      'id']) // Use widget.game['id'] for consistency
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Text('Error loading comments.');
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                    child:
                                        Text('No comments yet. Be the first!')),
                              );
                            }
                            final comments = snapshot.data!.docs;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final commentData = comments[index].data()
                                    as Map<String, dynamic>;
                                final isOwner =
                                    commentData['userId'] == user?.uid;
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  elevation: 1,
                                  child: ListTile(
                                    title: Text(commentData['text'] ?? ''),
                                    subtitle: Text(
                                        "By: ${commentData['userEmail'] ?? 'Anonymous'}"),
                                    trailing: isOwner
                                        ? IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red.shade400),
                                            onPressed: () => _deleteComment(
                                                comments[index].id),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        if (user != null)
                          Padding(
                            // Added padding around comment input
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: "Leave a comment...",
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.send,
                                      color: Theme.of(context).primaryColor),
                                  onPressed: _submitComment,
                                  tooltip: "Send comment",
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            // Prompt to log in to comment
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text("Please log in to leave a comment.",
                                style: TextStyle(color: Colors.grey.shade700)),
                          ),
                        const SizedBox(height: 20), // Extra space at the bottom
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
