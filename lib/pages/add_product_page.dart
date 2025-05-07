import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
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
        final response = await _apiService.addProduct(
          name: _nameController.text,
          description: _descController.text,
          price: double.parse(_priceController.text),
          category: _selectedCategoryId!,
          stockQuantity: int.tryParse(_stockController.text) ?? 0,
        );
        if (response['name'] != null) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product added successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add product: ${response['message'] ?? 'Unknown error'}')),
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
      appBar: AppBar(title: Text('Add Product')),
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
                child: _isLoading ? CircularProgressIndicator() : Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 