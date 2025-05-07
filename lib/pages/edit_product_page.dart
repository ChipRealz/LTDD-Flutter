import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing product data
    _nameController.text = widget.product['name'] ?? '';
    _descController.text = widget.product['description'] ?? '';
    _priceController.text = widget.product['price']?.toString() ?? '';
    _stockController.text = widget.product['stockQuantity']?.toString() ?? '';
    _selectedCategoryId = widget.product['category']?['_id'] ?? widget.product['category'];
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      setState(() => _isLoading = true);
      try {
        final response = await _apiService.updateProduct(
          productId: widget.product['_id'],
          name: _nameController.text,
          description: _descController.text,
          price: double.parse(_priceController.text),
          category: _selectedCategoryId!,
          stockQuantity: int.tryParse(_stockController.text) ?? 0,
        );
        if (response['name'] != null) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product updated successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update product: ${response['message'] ?? 'Unknown error'}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter product name' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                items: _categories
                    .map((cat) => DropdownMenuItem<String>(
                          value: cat['_id'] as String,
                          child: Text(cat['name']),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                decoration: InputDecoration(labelText: 'Category'),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? CircularProgressIndicator() : Text('Update Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }
} 