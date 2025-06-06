// 📁 my_reviews.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:praktikum_1/widget/navigation.dart';
import 'package:praktikum_1/widget/game_search_page.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});
  @override
  _MyReviewsPageState createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final CollectionReference reviewsRef =
      FirebaseFirestore.instance.collection('reviews');

  List<dynamic> games = [];

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames() async {
    final url = Uri.parse(
        'https://api.rawg.io/api/games?key=2b0a2ae08e954536832a28e84709f26c');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        games = data['results'];
      });
    } else {
      throw Exception('Failed to load games');
    }
  }

  void _showReviewDialog({DocumentSnapshot? review}) {
    String selectedGameId = review?['gameId'] ?? '';
    String selectedGameName = review?['title'] ?? '';
    String coverUrl = review?['coverUrl'] ?? '';
    final descriptionController =
        TextEditingController(text: review?['description'] ?? '');
    double rating = review?['rating']?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              review == null ? 'Add Review' : 'Edit Review',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.search),
                    label: Text(
                      selectedGameName.isEmpty
                          ? 'Select a Game'
                          : selectedGameName,
                      style: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () async {
                      final selected = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GameSearchPage()),
                      );

                      if (selected != null) {
                        setDialogState(() {
                          selectedGameId = selected['id'];
                          selectedGameName = selected['name'];
                          coverUrl = selected['coverUrl'];
                          print("Selected game: $selectedGameName");
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Text("Rating: ${rating.toStringAsFixed(1)}"),
                  Slider(
                    min: 0,
                    max: 5,
                    divisions: 10,
                    value: rating,
                    label: rating.toStringAsFixed(1),
                    onChanged: (value) {
                      setDialogState(() {
                        rating = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1b2838),
                ),
                child: const Text('Save'),
                onPressed: () async {
                  if (selectedGameId.isEmpty || user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a game")),
                    );
                    return;
                  }

                  final data = {
                    'gameId': selectedGameId,
                    'title': selectedGameName,
                    'description': descriptionController.text.trim(),
                    'coverUrl': coverUrl,
                    'rating': rating,
                    'userId': user!.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                  };

                  try {
                    if (review == null) {
                      await reviewsRef.add(data);
                    } else {
                      await reviewsRef.doc(review.id).update(data);
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save review: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteReview(String docId) async {
    await reviewsRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text('Login required'));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Reviews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5F5F5), // <- Light white/gray color
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1b2838), Color(0xFF171a21)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reviewsRef
            .where('userId', isEqualTo: user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: review['coverUrl'] != null &&
                          review['coverUrl'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            review['coverUrl'],
                            width: 50,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(
                    review['title'] ?? 'No Title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (review['description'] != null &&
                          review['description'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(review['description']),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Rating: ${review['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _showReviewDialog(review: review);
                      if (value == 'delete') _deleteReview(review.id);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 240, 241, 243),
        child: const Icon(Icons.add),
        onPressed: () => _showReviewDialog(),
      ),
      bottomNavigationBar: const CustomNavigationBar(selectedIndex: 1),
    );
  }
}
