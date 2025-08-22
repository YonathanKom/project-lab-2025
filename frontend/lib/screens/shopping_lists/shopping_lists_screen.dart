import 'package:fastflutter/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/household.dart';
import '../../providers/auth_provider.dart';
import '../../api/services/shopping_list_service.dart';
import '../../models/shopping_list.dart';
import '../../utils/routes.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/shopping_list/shopping_list_tile.dart';
import '../../widgets/theme_toggle.dart';
import 'edit_shopping_list_screen.dart';

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
  List<Household> _availableHouseholds = [];

  @override
  void initState() {
    super.initState();
    _shoppingListService = ShoppingListService(
      baseUrl,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHouseholds();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh households every time we enter this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHouseholds();
    });
  }

  void _initializeHouseholds() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null && user.householdIds.isNotEmpty) {
      _availableHouseholds = user.households;
      _selectedHouseholdId = user.households.first.id;
      _loadShoppingLists();
    } else {
      // Handle case when user has no households - not an error, just empty state
      setState(() {
        _availableHouseholds = [];
        _selectedHouseholdId = null;
        _shoppingLists = [];
        _isLoading = false;
        _errorMessage = ''; // No error message for empty state
      });
    }
  }

  Future<void> _refreshHouseholds() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Refresh user data from server to get latest households
    await authProvider.refreshUserData();

    if (!mounted) return;

    final user = authProvider.user;
    if (user != null && user.households.isNotEmpty) {
      final oldSelectedId = _selectedHouseholdId;
      _availableHouseholds = user.households;

      // Keep the same household selected if it still exists, otherwise select first
      if (oldSelectedId != null &&
          user.households.any((h) => h.id == oldSelectedId)) {
        _selectedHouseholdId = oldSelectedId;
      } else {
        _selectedHouseholdId = user.households.first.id;
      }

      // Reload shopping lists with updated household data
      _loadShoppingLists();
    } else {
      // Handle case when user has no households - not an error, just empty state
      setState(() {
        _availableHouseholds = [];
        _selectedHouseholdId = null;
        _shoppingLists = [];
        _isLoading = false;
        _errorMessage = ''; // No error message for empty state
      });
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

      // Check if we have a valid household selected
      if (_selectedHouseholdId == null) {
        setState(() {
          _shoppingLists = [];
          _isLoading = false;
          // No error message - empty state is normal
        });
        return;
      }

      final lists = await _shoppingListService.getShoppingLists(
        token: token,
        householdId: _selectedHouseholdId,
      );

      if (mounted) {
        setState(() {
          _shoppingLists = lists; // Handle null response
          _isLoading = false;
          // Clear error message on successful load (even if empty list)
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shoppingLists = []; // Ensure list is reset on error
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

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditShoppingListScreen(
          householdId: _selectedHouseholdId,
        ),
      ),
    );

    if (result == true) {
      _loadShoppingLists();
    }
  }

  Future<void> _editShoppingList(ShoppingList shoppingList) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditShoppingListScreen(
          shoppingList: shoppingList,
        ),
      ),
    );

    if (result == true) {
      _loadShoppingLists();
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

        await _shoppingListService.deleteShoppingList(
            listId: list.id, token: token);

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
                    (household) => PopupMenuItem(
                      value: household.id, // Changed from id to household.id
                      child: Row(
                        children: [
                          Icon(
                            _selectedHouseholdId == household.id
                                ? Icons.check
                                : Icons.home_outlined,
                            size: 20,
                            color: _selectedHouseholdId == household.id
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(household
                              .name), // Changed from 'Household $id' to household.name
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadShoppingLists,
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
            Navigator.pushNamed(
              context,
              Routes.shoppingListDetails,
              arguments: {'shoppingList': list},
            );
          },
          onEdit: () => _editShoppingList(list),
          onDelete: () => _deleteShoppingList(list),
        );
      },
    );
  }
}
