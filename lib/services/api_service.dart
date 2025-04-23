import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart'; // Import User model

class ApiService {
  static const String baseUrl = 'http://localhost:5000'; // Update for production

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String dateOfBirth,
    String role = 'user',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'dateOfBirth': dateOfBirth,
        'role': role,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyOTP(String userId, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/verifyOTP'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'otp': otp}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> resendOTP(String userId, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/resendOTPVerification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'email': email}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/requestPasswordReset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> resetPassword(String userId, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/resetPassword'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<List<User>> getUsers() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.get(
      Uri.parse('$baseUrl/user/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((json) => User.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch users: ${response.body}');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
}