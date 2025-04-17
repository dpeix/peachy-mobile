import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/colors.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String message;
  final String date;
  final String avatarUrl;

  const PostCard({
    super.key,
    required this.username,
    required this.message,
    required this.date,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(avatarUrl),
            ),
            const SizedBox(width: 12),
            // Contenu du post
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nom de l'utilisateur
                      Text(
                        username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.textColor,
                        ),
                      ),
                      // Date
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Message
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostList extends StatefulWidget {
  const PostList({super.key});

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    try {
      final posts = await ApiService.fetchPosts();
      posts.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
      return posts;
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _refreshPosts,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }

          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                username: post['username'] ?? 'Unknown',
                message: post['body'] ?? '',
                date: _formatTimeAgo(post['createdAt'] ?? ''),
                avatarUrl: 'https://via.placeholder.com/48',
              );
            },
          );
        },
      ),
    );
  }
}

/// Helper method to format time into "Xh ago" or similar.
String _formatTimeAgo(String dateTime) {
  final date = DateTime.parse(dateTime);
  final duration = DateTime.now().difference(date);
  if (duration.inMinutes < 60) {
    return "${duration.inMinutes}m";
  } else if (duration.inHours < 24) {
    return "${duration.inHours}h";
  } else {
    return "${duration.inDays}j";
  }
}

