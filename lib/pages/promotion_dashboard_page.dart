import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PromotionDashboardPage extends StatefulWidget {
  const PromotionDashboardPage({super.key});

  @override
  State<PromotionDashboardPage> createState() => _PromotionDashboardPageState();
}

class _PromotionDashboardPageState extends State<PromotionDashboardPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _promotions = [];
  bool _isLoading = false;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPromotions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPromotions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final promotions = await _apiService.getPromotions();
      setState(() {
        _promotions = promotions;
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

  void _showCreatePromotionDialog() {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final minOrderController = TextEditingController();
    String selectedType = 'percent';
    DateTime expiryDate = DateTime.now().add(Duration(days: 30));
    String? selectedUserId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Promotion'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: InputDecoration(labelText: 'Promotion Code'),
                  validator: (v) => v?.isEmpty ?? true ? 'Enter promotion code' : null,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: [
                    DropdownMenuItem(value: 'percent', child: Text('Percentage')),
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                  ],
                  onChanged: (v) => setState(() => selectedType = v!),
                  decoration: InputDecoration(labelText: 'Discount Type'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: discountController,
                  decoration: InputDecoration(
                    labelText: selectedType == 'percent' ? 'Discount Percentage' : 'Discount Amount',
                    hintText: selectedType == 'percent' ? 'Enter percentage (e.g., 10)' : 'Enter amount',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Enter discount value';
                    final value = double.tryParse(v!);
                    if (value == null) return 'Enter a valid number';
                    if (selectedType == 'percent' && (value < 0 || value > 100)) {
                      return 'Percentage must be between 0 and 100';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: minOrderController,
                  decoration: InputDecoration(
                    labelText: 'Minimum Order Value',
                    hintText: 'Enter minimum order value (optional)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                ListTile(
                  title: Text('Expiry Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(expiryDate)),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: expiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => expiryDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await _apiService.createPromotion(
                    code: codeController.text,
                    discount: double.parse(discountController.text),
                    type: selectedType,
                    minOrderValue: minOrderController.text.isNotEmpty
                        ? double.parse(minOrderController.text)
                        : null,
                    expiresAt: expiryDate,
                    userId: selectedUserId,
                  );
                  Navigator.pop(context);
                  _fetchPromotions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Promotion created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create promotion: $e')),
                  );
                }
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionList(List<Map<String, dynamic>> promotions) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (promotions.isEmpty) {
      return Center(child: Text('No promotions found'));
    }
    return RefreshIndicator(
      onRefresh: _fetchPromotions,
      child: ListView.builder(
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          final code = promotion['code'] ?? '';
          final type = promotion['type'] ?? '';
          final discount = promotion['discount'] ?? 0;
          final minOrderValue = promotion['minOrderValue'];
          final expiresAtStr = promotion['expiresAt'];
          DateTime? expiresAt;
          try {
            expiresAt = expiresAtStr != null ? DateTime.parse(expiresAtStr) : null;
          } catch (_) {
            expiresAt = null;
          }
          final isExpired = expiresAt != null ? expiresAt.isBefore(DateTime.now()) : false;

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: isExpired ? Colors.grey[200] : null,
            child: ListTile(
              title: Text(code),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discount: ${type == 'percent' ? '$discount%' : '\$$discount'}',
                  ),
                  if (minOrderValue != null)
                    Text('Min Order: \$$minOrderValue'),
                  Text(
                    expiresAt != null
                        ? 'Expires: ${DateFormat('MMM dd, yyyy').format(expiresAt)}'
                        : 'Expires: Invalid date',
                    style: TextStyle(
                      color: isExpired ? Colors.red : null,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  try {
                    await _apiService.deletePromotion(promotion['_id']);
                    _fetchPromotions();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Promotion deleted')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Delete failed: $e')),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> activePromotions = _promotions.where((p) {
      try {
        return p['expiresAt'] != null && DateTime.parse(p['expiresAt']).isAfter(DateTime.now());
      } catch (_) {
        return false;
      }
    }).toList();
    List<Map<String, dynamic>> expiredPromotions = _promotions.where((p) {
      try {
        return p['expiresAt'] != null && DateTime.parse(p['expiresAt']).isBefore(DateTime.now());
      } catch (_) {
        return false;
      }
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Promotion Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active Promotions'),
            Tab(text: 'Expired Promotions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPromotionList(activePromotions),
          _buildPromotionList(expiredPromotions),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePromotionDialog,
        tooltip: 'Create Promotion',
        child: Icon(Icons.add),
      ),
    );
  }
} 