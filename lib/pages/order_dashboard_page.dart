import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order.dart';

class OrderDashboardPage extends StatefulWidget {
  const OrderDashboardPage({super.key});

  @override
  State<OrderDashboardPage> createState() => _OrderDashboardPageState();
}

class _OrderDashboardPageState extends State<OrderDashboardPage> {
  final ApiService _apiService = ApiService();
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _limit = 10;
  int _totalPages = 1;
  String? _selectedStatus;
  final List<String> _statuses = [
    'NEW', 'CONFIRMED', 'PREPARING', 'DELIVERING', 'DELIVERED', 'CANCELED', 'CANCELREQUESTED'
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getAllOrders(
        page: _page,
        limit: _limit,
        status: _selectedStatus,
      );
      final orders = (result['orders'] as List<dynamic>? ?? [])
          .map((json) => Order.fromJson(json))
          .toList();
      setState(() {
        _orders = orders;
        _totalPages = result['totalPages'] ?? 1;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeOrderStatus(Order order, String newStatus) async {
    try {
      await _apiService.updateOrderStatus(orderId: order.id, status: newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
      _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ExpansionTile(
              title: Text('Order #${order.orderNumber ?? order.id}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User: ${order.userId}'),
                  Text('Status: ${order.status}'),
                  Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
                  Text('Created: ${order.createdAt}'),
                ],
              ),
              children: [
                ...order.items.map((item) => ListTile(
                      title: Text(item.name ?? item.productId),
                      subtitle: Text('Qty: ${item.quantity} x \$${item.price}'),
                      trailing: Text('= \$${(item.total ?? 0).toStringAsFixed(2)}'),
                    )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text('Change Status:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: order.status,
                        items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null && newStatus != order.status) {
                            _changeOrderStatus(order, newStatus);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status History:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...order.statusHistory.map((h) => Text(
                            '${h.status} at ${h.timestamp}: ${h.note ?? ''}',
                            style: const TextStyle(fontSize: 12),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Dashboard'),
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            hint: const Text('Filter by Status'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
                _page = 1;
              });
              _fetchOrders();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildOrderList()),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _page > 1
                        ? () {
                            setState(() {
                              _page--;
                            });
                            _fetchOrders();
                          }
                        : null,
                  ),
                  Text('Page $_page/$_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _page < _totalPages
                        ? () {
                            setState(() {
                              _page++;
                            });
                            _fetchOrders();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 