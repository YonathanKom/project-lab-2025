import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/shopping_list.dart';
import '../../models/catalog_item.dart';
import '../../api/services/shopping_list_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/items/item_search_dialog.dart';

class AddEditItemScreen extends StatefulWidget {
  final ShoppingItem? item;
  final int shoppingListId;

  const AddEditItemScreen({
    super.key,
    this.item,
    required this.shoppingListId,
  });

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _itemCodeController = TextEditingController();

  final ShoppingListService _shoppingListService = ShoppingListService(baseUrl);

  bool _isLoading = false;
  bool _isFormValid = false;
  CatalogItem? _selectedCatalogItem;
  bool _isFromCatalog = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description ?? '';
      _quantityController.text = widget.item!.quantity.toString();
      if (widget.item!.itemCode != null) {
        _itemCodeController.text = widget.item!.itemCode!;
        _isFromCatalog = true;
      }
      if (widget.item!.price != null) {
        _priceController.text = widget.item!.price!.toStringAsFixed(2);
      }
    } else {
      _quantityController.text = '1';
    }

    _nameController.addListener(_validateForm);
    _quantityController.addListener(_validateForm);
    _priceController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _itemCodeController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an item name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a quantity';
    }

    if (_selectedCatalogItem?.isWeighted == true) {
      final quantity = double.tryParse(value);
      if (quantity == null || quantity <= 0) {
        return 'Please enter a valid quantity';
      }
    } else {
      final quantity = int.tryParse(value);
      if (quantity == null || quantity < 1) {
        return 'Please enter a valid quantity';
      }
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final price = double.tryParse(value);
      if (price == null || price < 0) {
        return 'Please enter a valid price';
      }
    }
    return null;
  }

  Future<void> _selectFromCatalog() async {
    final result = await showDialog<CatalogItem>(
      context: context,
      builder: (context) => const ItemSearchDialog(),
    );

    if (result != null) {
      setState(() {
        _selectedCatalogItem = result;
        _isFromCatalog = true;
        _nameController.text = result.name;
        _itemCodeController.text = result.itemCode;
        if (result.manufacturerDescription != null) {
          _descriptionController.text = result.manufacturerDescription!;
        }
        if (result.currentPrice != null) {
          _priceController.text = result.currentPrice!.toStringAsFixed(2);
        }
        // Set quantity based on package info
        if (result.qtyInPackage != null && result.qtyInPackage! > 0) {
          _quantityController.text = '1'; // One package
        }
      });
      _validateForm();
    }
  }

  Future<void> _saveItem() async {
    if (!_isFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final itemData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'quantity': _selectedCatalogItem?.isWeighted == true
            ? double.parse(_quantityController.text)
            : int.parse(_quantityController.text),
        'price': _priceController.text.trim().isEmpty
            ? null
            : double.parse(_priceController.text),
        'item_code': _itemCodeController.text.trim().isEmpty
            ? null
            : _itemCodeController.text.trim(),
      };

      if (widget.item != null) {
        // Update existing item
        await _shoppingListService.updateShoppingItem(
          listId: widget.shoppingListId,
          itemId: widget.item!.id,
          itemData: itemData,
          token: authProvider.token!,
        );
        _showSuccessSnackBar('Item updated successfully');
      } else {
        // Create new item
        await _shoppingListService.createShoppingItem(
          listId: widget.shoppingListId,
          itemData: itemData,
          token: authProvider.token!,
        );
        _showSuccessSnackBar('Item added successfully');
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to trigger refresh
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildCatalogSelection() {
    return Card(
      child: InkWell(
        onTap: _selectFromCatalog,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCatalogItem != null
                          ? 'Selected from catalog'
                          : 'Select from catalog',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (_selectedCatalogItem != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedCatalogItem!.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Item' : 'Add Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCatalogSelection(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              validator: _validateName,
              decoration: InputDecoration(
                labelText: 'Item Name *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.shopping_bag),
                suffixIcon:
                    _isFromCatalog ? const Icon(Icons.lock, size: 16) : null,
              ),
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isLoading && !_isFromCatalog,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    validator: _validateQuantity,
                    decoration: InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                      prefixIcon: _selectedCatalogItem?.isWeighted == true &&
                              _selectedCatalogItem?.unitOfMeasure != null
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _selectedCatalogItem!.unitOfMeasure!,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            )
                          : const Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _selectedCatalogItem?.isWeighted == true
                        ? [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,3}'))
                          ]
                        : [FilteringTextInputFormatter.digitsOnly],
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    validator: _validatePrice,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          const Text('₪', style: TextStyle(fontSize: 16)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 48),
                      suffixIcon: _isFromCatalog
                          ? const Icon(Icons.lock, size: 16)
                          : null,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    enabled: !_isLoading && !_isFromCatalog,
                  ),
                ),
              ],
            ),
            if (_itemCodeController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemCodeController,
                decoration: const InputDecoration(
                  labelText: 'Item Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                enabled: false, // Read-only when from catalog
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isFormValid && !_isLoading ? _saveItem : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditMode ? 'Update Item' : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}
