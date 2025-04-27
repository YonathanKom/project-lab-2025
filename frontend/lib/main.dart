import 'package:flutter/material.dart';
import 'product_page.dart'; // Import your new file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping List App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ShoppingListScreen(),
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<Map<String, dynamic>> _products = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body:
          _products.isEmpty
              ? const Center(child: Text('No items in your list'))
              : ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ListTile(
                    title: Text(product['name']),
                    subtitle: Text('${product['quantity']} ${product['unit']}'),
                    onTap: () => _editProduct(index),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductPage()),
    );

    if (result != null) {
      setState(() {
        _products.add(result);
      });
    }
  }

  Future<void> _editProduct(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPage(product: _products[index]),
      ),
    );

    if (result == 'delete') {
      setState(() {
        _products.removeAt(index);
      });
    } else if (result != null) {
      setState(() {
        _products[index] = result;
      });
    }
  }
}
