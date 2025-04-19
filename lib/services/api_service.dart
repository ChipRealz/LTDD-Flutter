import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000'; // Update with your server URL

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

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
}