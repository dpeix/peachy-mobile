import 'package:flutter/material.dart';
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
      body: const PostList(), // Replace token display with PostList
      bottomNavigationBar: NavBar(
        currentIndex: 0, // Set the index for the Profile tab
        onTap: (index) {
          // Navigation logic is already handled in NavBar
        },
      ), // Corrected to use Navbar widget
    );
  }
}
