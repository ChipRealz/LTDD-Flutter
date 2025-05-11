import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryDashboardPage extends StatefulWidget {
  const CategoryDashboardPage({super.key});

  @override
  State<CategoryDashboardPage> createState() => _CategoryDashboardPageState();
}

class _CategoryDashboardPageState extends State<CategoryDashboardPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
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

  void _deleteCategory(String categoryId) async {
    try {
      await _apiService.deleteCategory(categoryId);
      _fetchCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descController = TextEditingController(text: category?['description'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              if (name.isEmpty) return;
              try {
                if (category == null) {
                  await _apiService.addCategory(name: name, description: desc);
                } else {
                  await _apiService.updateCategory(
                    categoryId: category['_id'],
                    name: name,
                    description: desc,
                  );
                }
                Navigator.pop(context);
                _fetchCategories();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(category == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Category Dashboard'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchCategories,
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return ListTile(
                        title: Text(category['name'] ?? ''),
                        subtitle: Text(category['description'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showCategoryDialog(category: category),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(category['_id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        tooltip: 'Add Category',
        child: Icon(Icons.add),
      ),
    );
  }
} 