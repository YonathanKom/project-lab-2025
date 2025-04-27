import 'package:flutter/material.dart';

class ProductPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductPage({super.key, this.product});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _notesController;
  List<Map<String, dynamic>> _priceComparisons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.product?['name'] ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.product?['quantity']?.toString() ?? '1',
    );
    _unitController = TextEditingController(
      text: widget.product?['unit'] ?? 'items',
    );
    _notesController = TextEditingController(
      text: widget.product?['notes'] ?? '',
    );

    if (widget.product != null) {
      _fetchPriceComparisons();
    }
  }

  void _fetchPriceComparisons() {
    // In a real app, you would fetch this data from your API
    setState(() {
      _isLoading = true;
    });

    // Simulating network delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _priceComparisons = [
          {'store': 'SuperMart', 'price': 3.99, 'distance': '0.8 mi'},
          {'store': 'GroceryPlus', 'price': 4.29, 'distance': '1.2 mi'},
          {'store': 'FreshMarket', 'price': 3.49, 'distance': '2.5 mi'},
        ];
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: const Text(
                          'Are you sure you want to remove this item?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Handle deletion
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(
                                context,
                                'delete',
                              ); // Return to previous screen with result
                            },
                            child: const Text('DELETE'),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product image (placeholder)
              if (widget.product != null)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                ),

              // Product name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity and unit row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., items, kg, liters',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              // Price comparison section (for editing existing products)
              if (widget.product != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Price Comparison',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _priceComparisons.length,
                    itemBuilder: (context, index) {
                      final store = _priceComparisons[index];
                      final bool isCheapest =
                          store['price'] ==
                          _priceComparisons
                              .map((s) => s['price'])
                              .reduce((a, b) => a < b ? a : b);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isCheapest ? Colors.green[50] : null,
                        child: ListTile(
                          title: Text(store['store']),
                          subtitle: Text('Distance: ${store['distance']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${store['price'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      isCheapest
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color: isCheapest ? Colors.green[700] : null,
                                ),
                              ),
                              if (isCheapest)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4.0),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],

              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Create product object
                    final product = {
                      'name': _nameController.text,
                      'quantity': double.parse(_quantityController.text),
                      'unit': _unitController.text,
                      'notes': _notesController.text,
                    };

                    // Return the product to previous screen
                    Navigator.pop(context, product);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.product == null ? 'ADD TO LIST' : 'SAVE CHANGES',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
