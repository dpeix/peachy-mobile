import 'package:flutter/material.dart';
import 'dart:developer';
import '../services/token_service.dart';
import '../services/api_service.dart';
import '../widgets/user_post_card.dart';
import '../theme/colors.dart';
import '../widgets/navbar.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<Map<String, dynamic>> _userData;
  final AppColors colors = AppColors(); // Instance des couleurs

  @override
  void initState() {
    super.initState();
    _userData = fetchUserData();
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final String? token = await TokenService.getToken();
    if (token == null) {
      throw Exception('Token non disponible');
    }
    return await ApiService.fetchUserDetails(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.backgroundColor, // Fond de la page
      appBar: AppBar(
        title: const Text('Profil utilisateur'),
        backgroundColor: colors.cardColor, // Couleur de l'app bar
      ),
      body: Column(
        children: [
          // Boîte contenant les informations utilisateur
          FutureBuilder<Map<String, dynamic>>(
            future: _userData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur : ${snapshot.error}'));
              } else {
                final user = snapshot.data!;

                return Container(
                  width: double.infinity, // Prend toute la largeur de l'écran
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colors.cardColor, // Fond du profil
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 2,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image de profil
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          user['picture']?.isNotEmpty == true
                              ? user['picture']
                              : 'lib/assets/icon/pp.png',
                        ),
                        onBackgroundImageError: (_, __) {
                          log('Erreur lors du chargement de l\'image utilisateur.');
                        }, // Icône si aucune image
                      ),
                      const SizedBox(height: 16),
                      // Nom d'utilisateur
                      Text(
                        user['username'] ?? 'Nom d\'utilisateur',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textColor, // Couleur du texte
                        ),
                      ),
                      // Bio (si disponible)
                      if (user['bio'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          user['bio'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textColor, // Couleur du texte
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
            },
          ),
          // Reste du contenu (si nécessaire)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.backgroundColor, // Fond de la liste de posts
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    spreadRadius: 2,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const UserPostList(),
            ), // Placeholder pour le reste du contenu
          ),
        ],
      ),
      bottomNavigationBar: NavBar(
        currentIndex: 1, // Index correspondant à la page de profil
        onTap: (index) {
          // Logique de navigation si nécessaire
        },
      ),
    );
  }
}
