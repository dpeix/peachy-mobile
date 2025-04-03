import 'package:flutter/material.dart';
import 'dart:developer'; // Import for logging

import '../services/api_service.dart';
import '../theme/colors.dart';
import '../services/token_service.dart';

class UserPostCard extends StatelessWidget {
  final String username;
  final String message;
  final String date;
  final String avatarUrl;

  const UserPostCard({
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
                          color: colors.textColor, // Use textColor from AppColors
                        ),
                      ),
                      // Date
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textColor, // Adjust opacity of textColor
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
                      color: colors.textColor, // Use textColor from AppColors
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

class UserPostList extends StatelessWidget {
  const UserPostList({super.key});

  Future<List<Map<String, dynamic>>> _fetchUserPosts() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        log('Token is null. User might not be logged in.');
        throw Exception('Error fetching user posts: No token found. Please log in.');
      }
      log('Token retrieved: $token');
      final posts = await ApiService.fetchUserPosts(token);
      log('Posts retrieved: $posts');
      return posts;
    } catch (e) {
      log('Error in _fetchUserPosts: $e');
      throw Exception('Error fetching user posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUserPosts(),
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
            return UserPostCard(
              username: post['username'] ?? 'Unknown',
              message: post['body'] ?? '',
              date: _formatTimeAgo(post['createdAt'] ?? ''),
              avatarUrl: post['picture'] ?? 'https://via.placeholder.com/48',
            );
          },
        );
      },
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
