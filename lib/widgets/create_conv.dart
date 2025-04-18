import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class CreateConvWidget extends StatefulWidget {
  const CreateConvWidget({super.key});

  @override
  State<CreateConvWidget> createState() => _CreateConvWidgetState();
}

class _CreateConvWidgetState extends State<CreateConvWidget> {
  late Future<List<Map<String, dynamic>>> _users;
  final Set<String> _selectedUserIds = {};
  final AppColors _colors = AppColors();

  @override
  void initState() {
    super.initState();
    _users = ApiService.fetchAllUsers(); // Fetch all users from the API
  }

  Future<void> _createConversation() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user.')),
      );
      return;
    }

    try {
      debugPrint('Selected user IDs: $_selectedUserIds'); // Log selected user IDs
      final List<String> userIris = _selectedUserIds.map((id) => '/api/users/$id').toList();
      debugPrint('Generated user IRIs: $userIris'); // Log generated IRIs
      final String newConvId = await ApiService.createConversation(_selectedUserIds.toList());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation created successfully!')),
      );
      Navigator.pop(context, newConvId); // Return the new conversation ID to the previous page
    } catch (e) {
      debugPrint('Error creating conversation: $e'); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create conversation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Conversation'),
        backgroundColor: _colors.cardColor,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No users found.',
                style: TextStyle(color: _colors.textColor.withOpacity(0.7)),
              ),
            );
          }

          final users = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = user['id'].toString();
                    return CheckboxListTile(
                      title: Text(
                        user['username'] ?? 'Unknown User',
                        style: TextStyle(color: _colors.textColor),
                      ),
                      value: _selectedUserIds.contains(userId),
                      onChanged: (isSelected) {
                        setState(() {
                          if (isSelected == true) {
                            _selectedUserIds.add(userId);
                          } else {
                            _selectedUserIds.remove(userId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                  backgroundColor: _colors.buttonColor,
                  ),
                  onPressed: _createConversation,
                  child: Text(
                  'Create Conversation',
                  style: TextStyle(color: _colors.textColorWhite),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
