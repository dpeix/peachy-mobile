import 'package:flutter/material.dart';
import 'package:jwt_decode/jwt_decode.dart'; // Import jwt_decode package
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../theme/colors.dart'; // Import AppColors

class MessagePage extends StatefulWidget {
  final String convId;

  const MessagePage({super.key, required this.convId});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  late Future<List<Map<String, dynamic>>> _messages;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  final AppColors _colors = AppColors(); // Create an instance of AppColors

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('No token found. Please log in again.');
    }
    final decodedToken = Jwt.parseJwt(token); // Decode the token to get user details
    final String currentUser = decodedToken['username'] ?? ''; // Extract the username
    setState(() {
      _messages = ApiService.fetchMessages(widget.convId, token).then((messages) {
        return messages.map((message) {
          message['isCurrentUser'] = message['author'] == currentUser; // Add a flag for current user
          return message;
        }).toList();
      });
    });
  }

  Future<void> _sendMessage() async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('No token found. Please log in again.');
    }

    final messageBody = _messageController.text.trim();
    if (messageBody.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await ApiService.sendMessage(widget.convId, token, messageBody);
      _messageController.clear();
      _loadMessages(); // Refresh messages after sending
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.backgroundColor, // Set background color
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: _colors.cardColor, // Use cardColor for AppBar
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages found for this conversation.',
                      style: TextStyle(color: _colors.textColor.withOpacity(0.7)),
                    ),
                  );
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message['isCurrentUser'] ?? false;
                    return Align(
                      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft, // Align based on user
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? _colors.buttonColor : _colors.textFieldColor, // Different color for current user
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['author'] ?? 'Unknown Author',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser ? _colors.textColorWhite : _colors.textColor, // White for current user
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['body'] ?? 'No content',
                              style: TextStyle(
                                color: isCurrentUser ? _colors.textColorWhite : _colors.textColor, // White for current user
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: _colors.textFieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _colors.buttonColor, // Icon color
                  ),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
