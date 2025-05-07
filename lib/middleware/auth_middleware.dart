import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthMiddleware extends StatefulWidget {
  final Widget child;
  
  const AuthMiddleware({Key? key, required this.child}) : super(key: key);
  
  @override
  State<AuthMiddleware> createState() => _AuthMiddlewareState();
}

class _AuthMiddlewareState extends State<AuthMiddleware> {
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    _checkSession();
  }
  
  Future<void> _checkSession() async {
    try {
      final response = await _apiService.checkAuth();
      if (response['status'] != 'SUCCESS') {
        await _apiService.clearSession();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      await _apiService.clearSession();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) => widget.child;
}