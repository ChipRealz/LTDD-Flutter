import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'manager_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  String? _adminId;
  final ApiService _apiService = ApiService();

  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await _apiService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response['status'] == 'PENDING') {
          setState(() {
            _isOtpSent = true;
            _adminId = response['adminId'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your email!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleOtpVerification() async {
    if (_otpController.text.isNotEmpty && _adminId != null) {
      try {
        final response = await _apiService.verifyOTP(_adminId!, _otpController.text);

        if (response['status'] == 'SUCCESS') {
          if (_adminId != null) {
            // Do not call saveSessionInfo here; it is handled in ApiService.verifyOTP with the correct JWT token
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification failed: missing adminId.')),
            );
            return;
          }
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ManagerDashboard(adminId: _adminId!),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _resendOtp() async {
    if (_adminId != null) {
      try {
        final response = await _apiService.resendOTP(_adminId!, _emailController.text);
        if (response['status'] == 'PENDING') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP resent to your email!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isOtpSent) ...[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleSignIn,
                  child: const Text('Sign In'),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                  ),
                  child: const Text('Forgot Password?'),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  ),
                  child: const Text('Register as Admin'),
                ),
              ] else ...[
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter the OTP';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleOtpVerification,
                  child: const Text('Verify OTP'),
                ),
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text('Resend OTP'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}