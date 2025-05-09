// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ProductDashboardPage extends StatefulWidget {
  const ProductDashboardPage({super.key});

  @override
  State<ProductDashboardPage> createState() => _ProductDashboardPageState();
}

class _ProductDashboardPageState extends State<ProductDashboardPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  String? _error;
  late TabController _tabController;
  // ignore: constant_identifier_names
  static const int LOW_STOCK_THRESHOLD = 15;
  // ignore: unused_field
  File? _selectedImage;
  // ignore: unused_field
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await _apiService.getProducts();
      setState(() {
        _products = products;
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

  void _deleteProduct(String productId) async {
    try {
      await _apiService.deleteProduct(productId);
      _fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  void _editProduct(Map<String, dynamic> product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: product),
      ),
    );
    if (result == true) {
      _fetchProducts();
    }
  }

  Widget _buildProductList(List<Map<String, dynamic>> products) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (products.isEmpty) {
      return Center(child: Text('No products found'));
    }
    return RefreshIndicator(
      onRefresh: _fetchProducts,
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final stockQuantity = product['stockQuantity'] ?? 0;
          final isLowStock = stockQuantity < LOW_STOCK_THRESHOLD;
          
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: isLowStock ? Colors.red.shade50 : null,
            child: ListTile(
              leading: product['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product['image'],
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                    ),
              title: Text(product['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price: \$${product['price']}'),
                  Row(
                    children: [
                      Text('Stock: ${product['stockQuantity']}'),
                      if (isLowStock) ...[
                        SizedBox(width: 8),
                        Icon(Icons.warning, color: Colors.red, size: 16),
                        Text(
                          'Low Stock',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editProduct(product),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(product['_id']),
                  ),
                ],
              ),
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
        title: Text('Product Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Products'),
            Tab(text: 'Low Stock'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductList(_products),
          _buildProductList(_products.where((p) => (p['stockQuantity'] ?? 0) < LOW_STOCK_THRESHOLD).toList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage()),
          );
          if (result == true) {
            _fetchProducts();
          }
        },
        tooltip: 'Add Product',
        child: Icon(Icons.add),
      ),
    );
  }
} 