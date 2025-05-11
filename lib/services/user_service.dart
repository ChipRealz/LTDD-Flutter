import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  final String baseUrl;
  final String token;

  UserService({required this.baseUrl, required this.token});

  Future<List<User>> getUsers() async {
    print('UserService token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> usersJson = data['data'];
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      print('Failed to load users: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load users: ${response.statusCode} - ${response.body}');
    }
  }

  Future<User> getUser(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return User.fromJson(data['data']);
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<User> updateUser(String id, Map<String, dynamic> updateData) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/users/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return User.fromJson(data['data']);
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
} 