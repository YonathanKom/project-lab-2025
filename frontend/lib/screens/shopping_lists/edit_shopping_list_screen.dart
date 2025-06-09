import 'package:fastflutter/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/services/shopping_list_service.dart';
import '../../models/shopping_list.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/theme_toggle.dart';

class EditShoppingListScreen extends StatefulWidget {
  final ShoppingList? shoppingList; // null for creating new list
  final int? householdId; // required for new lists

  const EditShoppingListScreen({
    super.key,
    this.shoppingList,
    this.householdId,
  });

  @override
  State<EditShoppingListScreen> createState() => _EditShoppingListScreenState();
}

class _EditShoppingListScreenState extends State<EditShoppingListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late ShoppingListService _shoppingListService;
  bool _isLoading = false;
  bool _isFormValid = false;

  bool get _isEditing => widget.shoppingList != null;

  @override
  void initState() {
    super.initState();
    _shoppingListService = ShoppingListService(baseUrl);

    // Pre-populate form if editing
    if (_isEditing) {
      _nameController.text = widget.shoppingList!.name;
      _isFormValid = true;
    }

    _nameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isCurrentlyValid = _formKey.currentState?.validate() ?? false;
    if (isCurrentlyValid != _isFormValid) {
      setState(() {
        _isFormValid = isCurrentlyValid;
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'List name is required';
    }
    if (value.trim().length < 2) {
      return 'List name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'List name cannot exceed 100 characters';
    }
    return null;
  }

  Future<void> _saveShoppingList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        _showErrorSnackBar('Authentication required');
        return;
      }

      final name = _nameController.text.trim();

      if (_isEditing) {
        // Update existing list
        final update = ShoppingListUpdate(name: name);
        await _shoppingListService.updateShoppingList(
          listId: widget.shoppingList!.id,
          listData: update,
          token: token,
        );
        _showSuccessSnackBar('Shopping list updated successfully');
      } else {
        // Create new list
        if (widget.householdId == null) {
          _showErrorSnackBar('Household ID is required');
          return;
        }

        final create = ShoppingListCreate(
          name: name,
          householdId: widget.householdId!,
        );
        await _shoppingListService.createShoppingList(
            listData: create, token: token);
        _showSuccessSnackBar('Shopping list created successfully');
      }

      // Navigate back with success result
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save shopping list: ${e.toString()}');
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Shopping List' : 'New Shopping List'),
        actions: const [ThemeToggle()],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'List Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'List Name',
                          hintText: 'Enter shopping list name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.list_alt),
                        ),
                        validator: _validateName,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (_isFormValid && !_isLoading) {
                            _saveShoppingList();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed:
                    _isFormValid && !_isLoading ? _saveShoppingList : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Update List' : 'Create List',
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
