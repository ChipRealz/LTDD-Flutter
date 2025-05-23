import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin.dart';

class ApiService {
  final String baseUrl = 'http://10.0.2.2:5000';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  // Save Session Info
  Future<void> saveSessionInfo(String? adminId, String? token) async {
    if (adminId != null) await _secureStorage.write(key: 'admin_id', value: adminId);
    if (token != null) await _secureStorage.write(key: 'jwt_token', value: token);
  }

  // Get Session Info
  Future<Map<String, String?>> getSessionInfo() async {
    final adminId = await _secureStorage.read(key: 'admin_id');
    final token = await _secureStorage.read(key: 'jwt_token');
    return {
      'adminId': adminId,
      'token': token,
    };
  }

  // Clear Session
  Future<void> clearSession() async {
    await _secureStorage.delete(key: 'admin_id');
    await _secureStorage.delete(key: 'jwt_token');
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    print('[DEBUG] JWT token used: $token');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    print('[DEBUG] Headers sent: $headers');
    return headers;
  }

  // Register Admin
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String dateOfBirth,
  }) async {
    final url = Uri.parse('$baseUrl/admin/signup');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'dateOfBirth': dateOfBirth,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  // Login Admin
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/admin/signin');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String adminId, String otp) async {
    final url = Uri.parse('$baseUrl/admin/verifyOTP');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adminId': adminId,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'SUCCESS') {
        await saveSessionInfo(adminId, data['token']);
      }
      return data;
    } else {
      throw Exception('Failed to verify OTP: ${response.body}');
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String adminId, String email) async {
    final url = Uri.parse('$baseUrl/admin/resendOTPVerification');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adminId': adminId,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to resend OTP: ${response.body}');
    }
  }

  // Request Password Reset
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/admin/requestPasswordReset');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to request password reset: ${response.body}');
    }
  }

  // Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/admin/resetPassword');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reset password: ${response.body}');
    }
  }

  // Check Authentication Status (dummy, no token)
  Future<Map<String, dynamic>> checkAuth() async {
    final url = Uri.parse('$baseUrl/admin/check-auth');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check auth status: ${response.body}');
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    final url = Uri.parse('$baseUrl/admin/logout');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      await clearSession(); // Clear local session data
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to logout: ${response.body}');
    }
  }

  // Fetch Admins (if needed)
  Future<List<Admin>> getAdmins() async {
    final url = Uri.parse('$baseUrl/admin/get-all-admins');
    final headers = await getAuthHeaders();
    final response = await _client.get(
      url,
      headers: headers,
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['status'] == 'SUCCESS' && body['data'] != null) {
        final List<dynamic> data = body['data'];
        return data.map((json) => Admin.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch admins: ${body['message'] ?? response.body}');
      }
    } else {
      throw Exception('Failed to fetch admins: ${response.body}');
    }
  }

  // Add Product with image upload
  Future<Map<String, dynamic>> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required int stockQuantity,
    File? image,
  }) async {
    final url = Uri.parse('$baseUrl/product/');
    final headers = await getAuthHeaders();
    
    // Create multipart request
    var request = http.MultipartRequest('POST', url);
    
    // Add headers
    request.headers.addAll({
      'Authorization': headers['Authorization'] ?? '',
    });
    
    // Add text fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['category'] = category;
    request.fields['stockQuantity'] = stockQuantity.toString();
    
    // Add image if provided
    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add product: ${response.body}');
    }
  }

  // Fetch categories for dropdown
  Future<List<Map<String, dynamic>>> getCategories() async {
    final url = Uri.parse('$baseUrl/category/');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch categories: ${response.body}');
    }
  }

  // Fetch all products
  Future<List<Map<String, dynamic>>> getProducts() async {
    final url = Uri.parse('$baseUrl/product/');
    final headers = await getAuthHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch products: ${response.body}');
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    final url = Uri.parse('$baseUrl/product/$productId');
    final headers = await getAuthHeaders();
    final response = await _client.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }

  // Update Product with image upload
  Future<Map<String, dynamic>> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required String category,
    required int stockQuantity,
    File? image,
  }) async {
    final url = Uri.parse('$baseUrl/product/$productId');
    final headers = await getAuthHeaders();
    
    // Create multipart request
    var request = http.MultipartRequest('PUT', url);
    
    // Add headers
    request.headers.addAll({
      'Authorization': headers['Authorization'] ?? '',    
    });
    
    // Add text fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['category'] = category;
    request.fields['stockQuantity'] = stockQuantity.toString();
    
    // Add image if provided
    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  // Add category
  Future<Map<String, dynamic>> addCategory({
    required String name,
    String? description,
  }) async {
    final url = Uri.parse('$baseUrl/category/');
    final headers = await getAuthHeaders();
    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add category: ${response.body}');
    }
  }

  // Update category
  Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    required String name,
    String? description,
  }) async {
    final url = Uri.parse('$baseUrl/category/$categoryId');
    final headers = await getAuthHeaders();
    final response = await _client.patch(
      url,
      headers: headers,
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update category: ${response.body}');
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    final url = Uri.parse('$baseUrl/category/$categoryId');
    final headers = await getAuthHeaders();
    final response = await _client.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }

  // Dispose
  void dispose() {
    _client.close();
  }

  Future<String> askChatbot(String message) async {
    final url = Uri.parse('$baseUrl/admin/chatbot');
    final headers = await getAuthHeaders();
    print('[DEBUG] Sending chatbot request to: $url');
    print('[DEBUG] Request body: {"message": "$message"}');
    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode({'message': message}),
    );
    print('[DEBUG] Chatbot response status: ${response.statusCode}');
    print('[DEBUG] Chatbot response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? 'No reply';
    } else {
      throw Exception('Failed to get chatbot reply: ${response.body}');
    }
  }

  // Get all promotions (admin)
  Future<List<Map<String, dynamic>>> getPromotions() async {
    final url = Uri.parse('$baseUrl/promotion/');
    final headers = await getAuthHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch promotions: ${response.body}');
    }
  }

  // Create a new promotion (admin)
  Future<Map<String, dynamic>> createPromotion({
    required String code,
    required double discount,
    required String type,
    double? minOrderValue,
    required DateTime expiresAt,
    String? userId,
  }) async {
    final url = Uri.parse('$baseUrl/promotion/create');
    final headers = await getAuthHeaders();
    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode({
        'code': code,
        'discount': discount,
        'type': type,
        'minOrderValue': minOrderValue,
        'expiresAt': expiresAt.toIso8601String(),
        'userId': userId,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create promotion: ${response.body}');
    }
  }

  // Delete a promotion (admin)
  Future<void> deletePromotion(String promotionId) async {
    final url = Uri.parse('$baseUrl/promotion/$promotionId');
    final headers = await getAuthHeaders();
    final response = await _client.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete promotion: ${response.body}');
    }
  }

  // Get all orders (admin)
  Future<Map<String, dynamic>> getAllOrders({int page = 1, int limit = 10, String? status, String sortBy = 'createdAt', String sortOrder = 'desc'}) async {
    final url = Uri.parse('$baseUrl/order/admin/get-all-orders?page=$page&limit=$limit&sortBy=$sortBy&sortOrder=$sortOrder${status != null ? '&status=$status' : ''}');
    final headers = await getAuthHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch orders: ${response.body}');
    }
  }

  // Update order status (admin)
  Future<Map<String, dynamic>> updateOrderStatus({required String orderId, required String status}) async {
    final url = Uri.parse('$baseUrl/order/admin/order/$orderId');
    final headers = await getAuthHeaders();
    final response = await _client.put(
      url,
      headers: headers,
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update order status: ${response.body}');
    }
  }

  // Get order by ID (admin)
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final url = Uri.parse('$baseUrl/order/$orderId');
    final headers = await getAuthHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch order: ${response.body}');
    }
  }
}