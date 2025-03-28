import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://std30.beaupeyrat.com';

  static Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPosts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/posts'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['member']);
    } else {
      throw Exception('Failed to load posts');
    }
  }
}
