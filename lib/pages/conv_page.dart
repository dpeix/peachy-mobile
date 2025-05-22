import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'message_page.dart';
import '../widgets/navbar.dart'; // Import the NavBar widget
import '../theme/colors.dart'; // Import AppColors
import '../widgets/create_conv.dart'; // Import CreateConvWidget

class ConvPage extends StatefulWidget {
  const ConvPage({super.key});

  @override
  State<ConvPage> createState() => _ConvPageState();
}

class _ConvPageState extends State<ConvPage> {
  late Future<List<Map<String, dynamic>>> _conversations;
  final AppColors _colors = AppColors(); // Create an instance of AppColors

  @override
  void initState() {
    super.initState();
    _conversations = ApiService.fetchConversations(); // No token parameter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.backgroundColor, // Set background color
      appBar: AppBar(
        title: const Text('Conversations'),
        backgroundColor: _colors.cardColor, // Use cardColor for AppBar
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('Unauthorized')) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Session expired. Please log in again.'),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colors.buttonColor, // Button color
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              );
            }
            return Center(child: Text('Error: $error'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: _colors.textColor.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations found.',
                    style: TextStyle(fontSize: 18, color: _colors.textColor.withOpacity(0.5)),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!;
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return FutureBuilder<List<String>>(
                future: ApiService.fetchConvUsernames(conv['id'].toString()), // Fetch usernames for the conversation
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return ListTile(
                      title: Text(
                        'Error loading conversation title',
                        style: TextStyle(color: _colors.textColor),
                      ),
                    );
                  } else {
                    final usernames = snapshot.data ?? [];
                    final uniqueUsernames = usernames.toSet().toList(); // Supprimer les doublons
                    final title = uniqueUsernames.join(', '); // Combine usernames into a single string
                    return Card(
                      color: _colors.cardColor,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          title,
                          style: TextStyle(color: _colors.textColor),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessagePage(convId: conv['id'].toString()),
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _colors.buttonColor, // Use buttonColor for the FAB
        onPressed: () async {
          final newConvId = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateConvWidget()),
          );
          if (newConvId != null) {
            setState(() {
              _conversations = ApiService.fetchConversations(); // Refresh the conversations list
            });
          }
        },
        child: const Icon(Icons.add, color: Colors.white), // Add icon for creating a new conversation
      ),
      bottomNavigationBar: NavBar(
        currentIndex: 2, // Set the current index to highlight the Conversations tab
        onTap: (index) {
          // Handle navigation logic in the NavBar widget
        },
      ),
    );
  }
}
