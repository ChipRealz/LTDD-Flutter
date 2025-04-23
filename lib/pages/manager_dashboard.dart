import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/user.dart';
import '../services/api_service.dart';

class ManagerDashboard extends StatefulWidget {
  final String userId;

  const ManagerDashboard({super.key, required this.userId});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  late IO.Socket socket;
  List<String> notifications = [];
  List<User> users = [];
  bool isLoadingUsers = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchUsers();
  }

  void _initSocket() {
    socket = IO.io(ApiService.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      print('Connected to Socket.IO server');
      socket.emit('join', widget.userId);
    });

    socket.onConnectError((error) {
      print('Socket.IO connection error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to notification server: $error')),
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

    socket.onDisconnect((_) => print('Disconnected'));
  }

  void _fetchUsers() async {
    setState(() {
      isLoadingUsers = true;
      errorMessage = null;
    });
    try {
      final fetchedUsers = await ApiService().getUsers();
      setState(() {
        users = fetchedUsers;
        isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoadingUsers = false;
      });
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manager Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Notifications'),
              Tab(text: 'Users'),
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
            // Users Tab
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Users:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: isLoadingUsers
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                          ? Center(child: Text(errorMessage!))
                          : users.isEmpty
                              ? const Center(child: Text('No users found'))
                              : ListView.builder(
                                  itemCount: users.length,
                                  itemBuilder: (context, index) {
                                    final user = users[index];
                                    return ListTile(
                                      title: Text(user.name),
                                      subtitle: Text('${user.email} | Role: ${user.role}'),
                                      leading: const Icon(Icons.person, color: Colors.deepPurple),
                                    );
                                  },
                                ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _fetchUsers,
                    child: const Text('Refresh Users'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}