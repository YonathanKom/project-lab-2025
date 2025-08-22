import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shopping_list.dart';
import '../../api/services/shopping_list_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/predictions/predictions_list.dart';
import '../../widgets/theme_toggle.dart';
import '../items/add_edit_item_screen.dart';
import 'price_comparison_screen.dart';

class ShoppingListDetailsScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ShoppingListDetailsScreen({
    super.key,
    required this.shoppingList,
  });

  @override
  State<ShoppingListDetailsScreen> createState() =>
      _ShoppingListDetailsScreenState();
}

class _ShoppingListDetailsScreenState extends State<ShoppingListDetailsScreen> {
  final ShoppingListService _shoppingListService = ShoppingListService(baseUrl);
  late ShoppingList _shoppingList;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _shoppingList = widget.shoppingList;
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final list = await _shoppingListService.getShoppingList(
        listId: _shoppingList.id,
        token: authProvider.token!,
      );
      setState(() {
        _shoppingList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load items: ${e.toString()}');
    }
  }

  Future<void> _toggleItem(ShoppingItem item) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _shoppingListService.toggleItemPurchased(
        listId: _shoppingList.id,
        itemId: item.id,
        isPurchased: !item.isPurchased,
        token: authProvider.token!,
      );
      _loadShoppingList();
    } catch (e) {
      _showSnackBar('Failed to update item: ${e.toString()}');
    }
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    // 👇 Grab context-dependent objects before the async gap
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _shoppingListService.deleteShoppingItem(
          listId: _shoppingList.id,
          itemId: item.id,
          token: authProvider.token!,
        );

        if (!mounted) return;
        _loadShoppingList();
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Failed to delete item: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildItemTile(ShoppingItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (_) => _toggleItem(item),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null)
              Text(item.description!,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            Row(
              children: [
                Text('Qty: ${item.quantity}'),
                if (item.price != null) ...[
                  const SizedBox(width: 16),
                  Text('₪${item.price!.toStringAsFixed(2)}'),
                ],
              ],
            ),
            if (item.addedByUsername != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Added by ${item.addedByUsername}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditItemScreen(
                    item: item,
                    shoppingListId: _shoppingList.id,
                  ),
                ),
              ).then((result) {
                if (result == true) _loadShoppingList();
              });
            } else if (value == 'delete') {
              _deleteItem(item);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _navigateToPriceComparison() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PriceComparisonScreen(
          shoppingList: widget.shoppingList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unpurchasedItems =
        _shoppingList.items.where((i) => !i.isPurchased).toList();
    final purchasedItems =
        _shoppingList.items.where((i) => i.isPurchased).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_shoppingList.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadShoppingList,
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Compare Prices',
            onPressed: _navigateToPriceComparison,
          ),
          const ThemeToggle(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadShoppingList,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  if (!_isLoading)
                    PredictionsList(
                      shoppingList: _shoppingList,
                      onItemAdded: _loadShoppingList,
                    ),
                  const SizedBox(height: 16),
                  if (unpurchasedItems.isEmpty && purchasedItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No items yet. Tap + to add items.'),
                      ),
                    ),
                  if (unpurchasedItems.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('To Purchase',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...unpurchasedItems.map(_buildItemTile),
                  ],
                  if (purchasedItems.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Purchased',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...purchasedItems.map(_buildItemTile),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditItemScreen(
                shoppingListId: _shoppingList.id,
              ),
            ),
          ).then((result) {
            if (result == true) _loadShoppingList();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
