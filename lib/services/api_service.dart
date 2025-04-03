import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:developer'; // Import for logging

class ApiService {
  static const String _baseUrl = 'https://std30.beaupeyrat.com';

  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['token'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/posts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['member']);
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchUserDetails(String token) async {
    try {
      final decodedToken = Jwt.parseJwt(token);
      final String userId = decodedToken['id'].toString();
      final String apiUrl = '$_baseUrl/api/users/$userId';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('Error fetching user details: Endpoint not found. Please verify the URL or contact the administrator.');
      } else {
        throw Exception('Error fetching user details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching user details: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUserPosts(String token) async {
    try {
      final decodedToken = Jwt.parseJwt(token);
      final String userId = decodedToken['id'].toString();
      final String userApiUrl = '$_baseUrl/api/users/$userId';

      log('Fetching user details for userId: $userId');
      final userResponse = await http.get(
        Uri.parse(userApiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      log('User API response status: ${userResponse.statusCode}');
      log('User API response body: ${userResponse.body}');

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;
        final List<String> postIRIs = List<String>.from(userData['posts']);
        log('User posts IRIs: $postIRIs');

        // Fetch details for each post
        final List<Map<String, dynamic>> posts = [];
        for (final postIri in postIRIs) {
          final postResponse = await http.get(
            Uri.parse('$_baseUrl$postIri'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (postResponse.statusCode == 200) {
            final postData = jsonDecode(postResponse.body) as Map<String, dynamic>;
            posts.add(postData);
          } else {
            log('Failed to fetch post details for $postIri: ${postResponse.statusCode}');
          }
        }

        log('Fetched posts: $posts');
        return posts;
      } else if (userResponse.statusCode == 404) {
        log('Error: User not found.');
        throw Exception('Error fetching user details: User not found.');
      } else {
        throw Exception('Error fetching user details: ${userResponse.statusCode} - ${userResponse.body}');
      }
    } catch (e) {
      log('Error in fetchUserPosts: $e');
      throw Exception('Error fetching user posts: $e');
    }
  }
}
