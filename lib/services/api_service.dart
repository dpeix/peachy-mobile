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
      final token = await TokenService.getToken(); // Retrieve token
      final response = await http.get(
        Uri.parse('$_baseUrl/api/posts'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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

  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['member']);
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  static Future<List<String>> createConvUsers(List<String> userIds) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final List<String> convUserIris = [];
      for (final userId in userIds) {
        final url = '$_baseUrl/api/conv_users';
        final body = jsonEncode({
          'users': '/api/users/$userId',
        });
        log('Creating ConvUser at $url with body: $body'); // Log the URL and body

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/ld+json',
          },
          body: body,
        );

        log('Response status: ${response.statusCode}'); // Log the response status
        log('Response body: ${response.body}'); // Log the response body

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          convUserIris.add(data['@id'] as String); // Add the IRI of the created ConvUser
        } else {
          throw Exception('Failed to create ConvUser: ${response.statusCode} - ${response.body}');
        }
      }
      return convUserIris;
    } catch (e) {
      log('Error creating ConvUsers: $e'); // Log the error
      throw Exception('Error creating ConvUsers: $e');
    }
  }

  static Future<String> createConversation(List<String> userIds) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      // Create ConvUsers and get their IRIs
      final List<String> convUserIris = await createConvUsers(userIds);

      final url = '$_baseUrl/api/convs';
      final body = jsonEncode({'convUsers': convUserIris});
      log('Creating conversation at $url with body: $body'); // Log the URL and body

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/ld+json',
        },
        body: body,
      );

      log('Response status: ${response.statusCode}'); // Log the response status
      log('Response body: ${response.body}'); // Log the response body

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['id'].toString(); // Return the ID of the created conversation
      } else {
        throw Exception('Failed to create conversation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error creating conversation: $e'); // Log the error
      throw Exception('Error creating conversation: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchConvUsers(String convId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/conv_users?convs=/api/convs/$convId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['member']);
      } else {
        throw Exception('Failed to fetch conv_users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching conv_users: $e');
    }
  }

  static Future<void> updateConvUserLastCheck(String convUserId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/api/conv_users/$convUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'date_last_check': DateTime.now().toIso8601String()}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update conv_user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating conv_user: $e');
    }
  }

  static Future<List<String>> fetchConvUsernames(String convId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final convUsersResponse = await http.get(
        Uri.parse('$_baseUrl/api/conv_users?convs=/api/convs/$convId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (convUsersResponse.statusCode != 200) {
        throw Exception('Failed to fetch conv_users: ${convUsersResponse.statusCode}');
      }

      final convUsersData = jsonDecode(convUsersResponse.body) as Map<String, dynamic>;
      final convUsers = List<Map<String, dynamic>>.from(convUsersData['member']);

      final List<String> usernames = [];
      for (final convUser in convUsers) {
        final userIri = convUser['users'] as String?;
        if (userIri != null) {
          final userId = userIri.split('/').last;
          final userResponse = await http.get(
            Uri.parse('$_baseUrl/api/users/$userId'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;
            usernames.add(userData['username'] as String);
          }
        }
      }

      return usernames;
    } catch (e) {
      log('Error fetching conversation usernames: $e');
      throw Exception('Error fetching conversation usernames: $e');
    }
  }
}
