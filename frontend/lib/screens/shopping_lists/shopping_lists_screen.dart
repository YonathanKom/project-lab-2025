import 'package:fastflutter/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/services/shopping_list_service.dart';
import '../../models/shopping_list.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/shopping_list/shopping_list_tile.dart';
import '../../widgets/theme_toggle.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  late ShoppingListService _shoppingListService;
  List<ShoppingList> _shoppingLists = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _selectedHouseholdId;
  List<int> _availableHouseholds = [];

  @override
  void initState() {
    super.initState();
    _shoppingListService = ShoppingListService(
      baseUrl: baseUrl,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHouseholds();
    });
  }

  void _initializeHouseholds() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null && user.householdIds.isNotEmpty) {
      _availableHouseholds = user.householdIds;
      _selectedHouseholdId = user.householdIds.first;
      _loadShoppingLists();
    }
  }

  Future<void> _loadShoppingLists() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      final lists = await _shoppingListService.getShoppingLists(
        token,
        householdId: _selectedHouseholdId,
      );

      if (mounted) {
        setState(() {
          _shoppingLists = lists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createShoppingList() async {
    if (_selectedHouseholdId == null) {
      _showSnackBar('Please select a household first');
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CreateListDialog(),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token!;
        final createData = ShoppingListCreate(
          name: result,
          householdId: _selectedHouseholdId!,
        );

        await _shoppingListService.createShoppingList(createData, token);
        _showSnackBar('Shopping list created successfully');
        _loadShoppingLists();
      } catch (e) {
        _showSnackBar(
            'Failed to create shopping list: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }
  }

  Future<void> _editShoppingList(ShoppingList list) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _CreateListDialog(initialName: list.name),
    );

    if (result != null && result.isNotEmpty && result != list.name) {
      if (!mounted) return;

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token!;
        final updateData = ShoppingListUpdate(name: result);

        await _shoppingListService.updateShoppingList(
            list.id, updateData, token);

        if (!mounted) return;
        _showSnackBar('Shopping list updated successfully');
        await _loadShoppingLists();
      } catch (e) {
        if (!mounted) return;
        _showSnackBar(
          'Failed to update shopping list: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _deleteShoppingList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Shopping List'),
        content: Text(
          'Are you sure you want to delete "${list.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token!;

        await _shoppingListService.deleteShoppingList(list.id, token);

        if (!mounted) return;
        _showSnackBar('Shopping list deleted successfully');
        await _loadShoppingLists();
      } catch (e) {
        if (!mounted) return;
        _showSnackBar(
          'Failed to delete shopping list: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        actions: [
          if (_availableHouseholds.length > 1)
            PopupMenuButton<int>(
              icon: const Icon(Icons.home_outlined),
              onSelected: (householdId) {
                setState(() {
                  _selectedHouseholdId = householdId;
                });
                _loadShoppingLists();
              },
              itemBuilder: (context) => _availableHouseholds
                  .map(
                    (id) => PopupMenuItem(
                      value: id,
                      child: Row(
                        children: [
                          Icon(
                            _selectedHouseholdId == id
                                ? Icons.check
                                : Icons.home_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('Household $id'),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          const ThemeToggle(),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadShoppingLists,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createShoppingList,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadShoppingLists,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_shoppingLists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Shopping Lists',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first shopping list to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _shoppingLists.length,
      itemBuilder: (context, index) {
        final list = _shoppingLists[index];
        return ShoppingListTile(
          shoppingList: list,
          onTap: () {
            // Navigate to shopping list details
            // Navigator.pushNamed(context, '/shopping-list-details', arguments: list.id);
          },
          onEdit: () => _editShoppingList(list),
          onDelete: () => _deleteShoppingList(list),
        );
      },
    );
  }
}

class _CreateListDialog extends StatefulWidget {
  final String? initialName;

  const _CreateListDialog({this.initialName});

  @override
  State<_CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<_CreateListDialog> {
  late TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Shopping List' : 'Create Shopping List'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'List Name',
            hintText: 'Enter shopping list name',
          ),
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a list name';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
