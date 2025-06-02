import 'package:fastflutter/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shopping_list.dart';
import '../../api/services/shopping_list_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/shopping_list/item_tile.dart';
import '../../widgets/theme_toggle.dart';

class ShoppingListDetailsScreen extends StatefulWidget {
  final int listId;
  final String? listName;

  const ShoppingListDetailsScreen({
    super.key,
    required this.listId,
    this.listName,
  });

  @override
  State<ShoppingListDetailsScreen> createState() =>
      _ShoppingListDetailsScreenState();
}

class _ShoppingListDetailsScreenState extends State<ShoppingListDetailsScreen> {
  late final ShoppingListService _shoppingListService;
  ShoppingList? _shoppingList;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _shoppingListService = ShoppingListService(baseUrl: baseUrl);
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

      final shoppingList =
          await _shoppingListService.getShoppingList(widget.listId, token);

      if (mounted) {
        setState(() {
          _shoppingList = shoppingList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load shopping list: ${e.toString()}';
          _isLoading = false;
        });
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadShoppingList,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_shoppingList == null) {
      return const Center(
        child: Text('Shopping list not found'),
      );
    }

    final items = _shoppingList!.items;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No items in this list',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShoppingList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ItemTile(
              item: item,
              onToggle: (item) => _toggleItemPurchased(item),
              onEdit: (item) => _editItem(item),
              onDelete: (item) => _deleteItem(item),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleItemPurchased(ShoppingItem item) async {
    // TODO: Implement when item update API is available
    _showSnackBar('Item toggle functionality coming soon');
  }

  Future<void> _editItem(ShoppingItem item) async {
    // TODO: Implement when item edit screen is available
    _showSnackBar('Item editing functionality coming soon');
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    // TODO: Implement when item delete API is available
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showSnackBar('Item deletion functionality coming soon');
    }
  }

  @override
  Widget build(BuildContext context) {
    final listName = _shoppingList?.name ?? widget.listName ?? 'Shopping List';

    return Scaffold(
      appBar: AppBar(
        title: Text(listName),
        actions: const [ThemeToggle()],
      ),
      drawer: const AppDrawer(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add item screen when available
          _showSnackBar('Add item functionality coming soon');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
