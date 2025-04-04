import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decode/jwt_decode.dart'; // Import for decoding JWT
import '../services/token_service.dart';
import '../theme/colors.dart'; // Corrected TokenService import
import 'package:flutter/scheduler.dart'; // Import for animation

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start off-screen at the bottom
      end: Offset.zero, // End at the center
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward(); // Start the animation
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final String content = _contentController.text.trim(); // Trim whitespace

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Content cannot be empty')), // Show error message
      );
      return; // Stop execution if content is empty
    }

    final String createdAt = DateTime.now().toUtc().toIso8601String(); // Ensure ISO 8601 format with UTC
    final bool state = true; // Initialize state to true

    try {
      final String? token = await TokenService.getToken(); // Retrieve token
      if (token == null) {
        throw Exception('User is not authenticated. Token is missing.');
      }

      print('Retrieved token: $token'); // Log the token for debugging

      final Map<String, dynamic> decodedToken = Jwt.parseJwt(token); // Decode token
      print('Decoded token: $decodedToken'); // Log the decoded token for debugging

      if (!decodedToken.containsKey('id') || decodedToken['id'] == null) {
        throw Exception('Invalid token: Missing or null user ID.');
      }

      final String userId = decodedToken['id'].toString(); // Extract user_id
      print('Extracted user ID: $userId'); // Log the extracted user ID

      final String userIri = 'https://std30.beaupeyrat.com/api/users/$userId'; // Construct user IRI

      final Map<String, dynamic> requestBody = {
        'body': content,
        'createdAt': createdAt,
        'state': state, // Add state to the request body
        'user': userIri, // Use user IRI instead of user_id
      };

      print('Submitting post with request body: $requestBody'); // Log request body

      setState(() {
        _isLoading = true;
      });

      print('Sending POST request to API...'); // Log request start
      final response = await http.post(
        Uri.parse('https://std30.beaupeyrat.com/api/posts'),
        headers: {
          'Content-Type': 'application/ld+json',
          'Authorization': 'Bearer $token', // Include token in headers
        },
        body: jsonEncode(requestBody), // Send request body
      );

      print('Response received: ${response.statusCode}'); // Log response status

      if (response.statusCode == 201) {
        print('Post created successfully'); // Log success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post created successfully')),
        );
        Navigator.of(context).pop(); // Close the modal
      } else {
        print('Failed to create post: ${response.body}'); // Log failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error occurred: $e'); // Log error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      print('Request completed'); // Log completion
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(); // Access AppColors

    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          insetPadding: EdgeInsets.zero, // Remove default padding
          backgroundColor: colors.backgroundColor, // Use backgroundColor for modal
          child: Scaffold(
            backgroundColor: colors.backgroundColor, // Ensure Scaffold also uses backgroundColor
            appBar: AppBar(
              backgroundColor: colors.buttonColor, // Use buttonColor for the AppBar
              title: const Text(
                'Create Post',
                style: TextStyle(color: Colors.white), // Ensure text color is white
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    _animationController.reverse().then((_) {
                      Navigator.of(context).pop(); // Close the modal after animation
                    });
                  },
                ),
              ],
            ),
            body: Container(
              color: colors.cardColor, // Use cardColor for the form background
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: TextStyle(color: colors.textColor), // Use textColor for label
                      filled: true,
                      fillColor: colors.backgroundColor, // Use textFieldColor for background
                    ),
                    style: TextStyle(color: colors.textColor), // Use textColor for input text
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonColor, // Use buttonColor for the button
                    ),
                    onPressed: _isLoading ? null : _submitPost,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Submit',
                            style: TextStyle(color: Colors.white), // Ensure text color is white
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
