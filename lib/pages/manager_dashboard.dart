import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/admin.dart';
import '../services/api_service.dart';
import 'product_dashboard_page.dart';
import 'category_dashboard_page.dart';
import 'chatbot_page.dart';
import 'promotion_dashboard_page.dart';

class ManagerDashboard extends StatefulWidget {
  final String adminId;

  const ManagerDashboard({super.key, required this.adminId});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  late IO.Socket socket;
  List<String> notifications = [];
  List<Admin> admins = [];
  bool isLoadingAdmins = false;
  String? errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchAdmins();
  }

  void _initSocket() {
    socket = IO.io(_apiService.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'withCredentials': true,
    });

    socket.connect();
    socket.onConnect((_) {
      print('Connected to Socket.IO server');
      socket.emit('join', widget.adminId);
    });

    socket.onConnectError((error) {
      print('Socket.IO connection error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect to notification server: $error'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              socket.connect();
            },
          ),
        ),
      );
    });

    socket.on('notification', (data) {
      if (data != null && data is Map && data.containsKey('message')) {
        setState(() {
          notifications.add(data['message'] as String);
        });
      } else {
        print('Invalid notification data: $data');
      }
    });

    socket.onDisconnect((_) => print('Disconnected from Socket.IO server'));
  }

  void _fetchAdmins() async {
    setState(() {
      isLoadingAdmins = true;
      errorMessage = null;
    });
    try {
      final fetchedAdmins = await _apiService.getAdmins();
      setState(() {
        admins = fetchedAdmins;
        isLoadingAdmins = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoadingAdmins = false;
      });
    }
  }

  void _logout() async {
    try {
      await _apiService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manager Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: 'Chatbot',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatbotPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Notifications'),
              Tab(text: 'Admins'),
              Tab(text: 'Products'),
              Tab(text: 'Categories'),
              Tab(text: 'Promotions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Notifications Tab
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Notifications:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: notifications.isEmpty
                      ? const Center(child: Text('No notifications yet'))
                      : ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) => ListTile(
                            title: Text(notifications[index]),
                            leading: const Icon(Icons.notifications, color: Colors.deepPurple),
                          ),
                        ),
                ),
              ],
            ),
            // Admins Tab
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Admins:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: isLoadingAdmins
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(errorMessage!),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchAdmins,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : admins.isEmpty
                              ? const Center(child: Text('No admins found'))
                              : ListView.builder(
                                  itemCount: admins.length,
                                  itemBuilder: (context, index) {
                                    final admin = admins[index];
                                    return ListTile(
                                      title: Text(admin.name),
                                      subtitle: Text(admin.email),
                                      leading: const Icon(Icons.person, color: Colors.deepPurple),
                                      trailing: admin.verified
                                          ? const Icon(Icons.verified, color: Colors.green)
                                          : const Icon(Icons.hourglass_empty, color: Colors.orange),
                                    );
                                  },
                                ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _fetchAdmins,
                    child: const Text('Refresh Admins'),
                  ),
                ),
              ],
            ),
            // Products Tab
            ProductDashboardPage(),
            // Categories Tab
            CategoryDashboardPage(),
            // Promotions Tab
            PromotionDashboardPage(),
          ],
        ),
      ),
    );
  }
}