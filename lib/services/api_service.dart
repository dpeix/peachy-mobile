import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:developer'; // Import for logging
import 'token_service.dart'; // Import TokenService

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

  static Future<List<Map<String, dynamic>>> fetchConversations() async {
    try {
      final token = await TokenService.getToken(); // Retrieve token
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      log('Fetching conversations with token: $token');

      // Fetch user details
      final decodedToken = Jwt.parseJwt(token);
      final String userId = decodedToken['id'].toString();
      log('Logged-in user ID: $userId');

      final userDetailsResponse = await http.get(
        Uri.parse('$_baseUrl/api/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (userDetailsResponse.statusCode != 200) {
        throw Exception('Failed to fetch user details: ${userDetailsResponse.statusCode}');
      }

      final userDetails = jsonDecode(userDetailsResponse.body) as Map<String, dynamic>;
      final List<String> userConvUsers = List<String>.from(userDetails['convUsers'] ?? []);
      log('User convUsers: $userConvUsers');

      // Fetch all conversations
      final response = await http.get(
        Uri.parse('$_baseUrl/api/convs'),
        headers: {'Authorization': 'Bearer $token'},
      );

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        log('Parsed response: $data');

        // Extract and filter conversations
        final List<dynamic> conversations = data['member'] ?? [];
        final filteredConversations = conversations.where((conv) {
          final List<dynamic> convUsers = conv['convUsers'] ?? [];
          log('Conversation ID: ${conv['id']}, convUsers: $convUsers');
          // Check if any of the user's convUsers are in the conversation's convUsers
          return convUsers.any((user) => userConvUsers.contains(user));
        }).toList();

        log('Filtered conversations: $filteredConversations');
        return List<Map<String, dynamic>>.from(filteredConversations);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token.');
      } else {
        throw Exception('Failed to fetch conversations: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching conversations: $e');
      throw Exception('Error fetching conversations: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMessages(String convId, String token, {int limit = 100}) async {
    try {
      final url = '$_baseUrl/api/messages?limit=$limit'; // Add limit parameter to the URL
      log('Fetching messages from URL: $url'); // Log the URL
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final messages = List<Map<String, dynamic>>.from(data['member']);
        // Filter messages by conversation ID
        final filteredMessages = messages.where((message) {
          final convIri = message['convs'] as String?;
          return convIri != null && convIri.endsWith('/$convId');
        }).map((message) {
          // Normalize field names and handle inconsistencies
          return {
            'id': message['id'],
            'author': message['author'] ?? 'Unknown Author',
            'body': message['body'] ?? '',
            'date_post': message['date_post'] ?? message['datePost'] ?? 'Unknown Date',
            'convs': message['convs'],
          };
        }).toList();

        log('Filtered messages for conversation ID $convId: $filteredMessages');
        return filteredMessages;
      } else if (response.statusCode == 404) {
        log('No messages found for conversation ID: $convId'); // Log the error
        return []; // Return an empty list instead of throwing an exception
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  static Future<void> sendMessage(String convId, String token, String body) async {
    try {
      final decodedToken = Jwt.parseJwt(token); // Decode the token to get user details
      final String author = decodedToken['username'] ?? 'Unknown'; // Extract the username or fallback
      final String datePost = DateTime.now().toIso8601String(); // Get the current timestamp in ISO 8601 format

      final url = '$_baseUrl/api/messages';
      log('Sending message to URL: $url'); // Log the URL
      log('Request payload: ${jsonEncode({
        'body': body,
        'convs': '/api/convs/$convId',
        'author': author,
        'date_post': datePost,
      })}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/ld+json', // Use the correct content type
        },
        body: jsonEncode({
          'body': body,
          'convs': '/api/convs/$convId', // Reference to the conversation
          'author': author, // Include the author field
          'date_post': datePost, // Include the date_post field
        }),
      );

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
      }

      log('Message sent successfully.');
    } catch (e) {
      log('Error sending message: $e');
      throw Exception('Error sending message: $e');
    }
  }
}
