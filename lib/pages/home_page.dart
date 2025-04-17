import 'package:flutter/material.dart';
import '../widgets/create_post.dart';
import '../widgets/post_card.dart';
import '../theme/colors.dart';
import '../widgets/navbar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors();

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      //appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger a refresh in the PostList widget
          // This will be handled by the PostList's state
        },
        child: const PostList(),
      ),
      bottomNavigationBar: NavBar(
        currentIndex: 0, // Set the index for the Profile tab
        onTap: (index) {
          // Navigation logic is already handled in NavBar
        },
      ), // Corrected to use Navbar widget
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.buttonColor, // Use buttonColor from AppColors
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const CreatePost(); // Open the CreatePost dialog directly
            },
          );
        },
        child: const Icon(Icons.add, color: Colors.white), // Ensure icon color is white
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
