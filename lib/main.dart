import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'pages/intro_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/manager_dashboard.dart';
import 'middleware/auth_middleware.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check for existing session
  final apiService = ApiService();
  final sessionInfo = await apiService.getSessionInfo();
  
  runApp(MyApp(initialRoute: sessionInfo['adminId'] != null ? '/dashboard' : '/intro'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/intro': (context) => const IntroPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => AuthMiddleware(
          child: ManagerDashboard(adminId: '...'), // You'll need to pass the adminId
        ),
      },
    );
  }
}