import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'manager_dashboard.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  String? _adminId;
  final ApiService _apiService = ApiService();

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await _apiService.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          dateOfBirth: _dobController.text,
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful! Welcome to your dashboard.')),
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
      appBar: AppBar(title: const Text('Register Admin')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isOtpSent) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your name';
                    if (!RegExp(r'^[a-zA-Z ]*$').hasMatch(value)) return 'Invalid name format';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                    if (value.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please select your date of birth';
                    try {
                      DateTime.parse(value);
                    } catch (e) {
                      return 'Invalid date format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleRegister,
                  child: const Text('Register'),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ),
                  child: const Text('Already have an account? Login'),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}