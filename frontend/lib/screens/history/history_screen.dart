// lib/screens/history/history_screen.dart

import 'package:fastflutter/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/theme_toggle.dart';
import '../../providers/auth_provider.dart';
import '../../models/history_item.dart';
import '../../models/shopping_list.dart';
import '../../api/services/history_service.dart';
import '../../api/services/shopping_list_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryService _historyService;
  late ShoppingListService _shoppingListService;
  final List<ShoppingListHistory> _historyItems = [];
  List<ShoppingList> _availableShoppingLists = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  Map<String, dynamic>? _stats;

  // Filter controls
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedHouseholdId;
  final TextEditingController _searchController = TextEditingController();

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _historyService = HistoryService(baseUrl);
    _shoppingListService = ShoppingListService(baseUrl);
    _loadHistory();
    _loadStats();
    _loadAvailableShoppingLists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _historyItems.clear();
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      final filter = HistoryFilter(
        startDate: _startDate,
        endDate: _endDate,
        householdId: _selectedHouseholdId,
        searchQuery: _searchController.text,
      );

      final items = await _historyService.getHistory(
        token: token,
        filter: filter,
        skip: _currentPage * _pageSize,
        limit: _pageSize,
      );

      setState(() {
        _historyItems.addAll(items);
        _currentPage++;
        _hasMore = items.length == _pageSize;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      final filter = HistoryFilter(
        startDate: _startDate,
        endDate: _endDate,
        householdId: _selectedHouseholdId,
        searchQuery: _searchController.text,
      );

      final stats = await _historyService.getHistoryStats(
        token: token,
        filter: filter,
      );

      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Silently fail for stats
    }
  }

  Future<void> _loadAvailableShoppingLists() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      final lists = await _shoppingListService.getShoppingLists(token: token);
      setState(() {
        _availableShoppingLists = lists;
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _restoreShoppingList(ShoppingListHistory historyItem) async {
    if (_availableShoppingLists.isEmpty) {
      _showSnackBar('No shopping lists available. Please create one first.');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RestoreShoppingListDialog(
        availableShoppingLists: _availableShoppingLists,
        originalName: historyItem.shoppingListName,
      ),
    );

    if (result != null) {
      try {
        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token!;

        final restoreData = RestoreToList(
          targetListId: result['targetListId'],
          targetListName: result['targetListName'],
        );

        final response = await _historyService.restoreShoppingList(
          historyId: historyItem.id,
          restoreData: restoreData,
          token: token,
        );

        if (!mounted) return;
        _showSnackBar(
            response['message'] ?? 'Shopping list restored successfully');
        _loadAvailableShoppingLists(); // Refresh available lists
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Failed to restore shopping list: ${e.toString()}');
      }
    }
  }

  Future<void> _restoreItem(
      ShoppingListHistory historyItem, HistoryShoppingItem item) async {
    if (_availableShoppingLists.isEmpty) {
      _showSnackBar('No shopping lists available. Please create one first.');
      return;
    }

    final selectedList = await showDialog<ShoppingList>(
      context: context,
      builder: (context) => _SelectShoppingListDialog(
        availableShoppingLists: _availableShoppingLists,
      ),
    );

    if (selectedList != null) {
      try {
        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token!;

        final response = await _historyService.restoreItem(
          historyId: historyItem.id,
          itemName: item.name,
          targetListId: selectedList.id,
          token: token,
        );

        if (!mounted) return;
        _showSnackBar(response['message'] ?? 'Item restored successfully');
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Failed to restore item: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        startDate: _startDate,
        endDate: _endDate,
        selectedHouseholdId: _selectedHouseholdId,
        onApply: (start, end, householdId) {
          setState(() {
            _startDate = start;
            _endDate = end;
            _selectedHouseholdId = householdId;
          });
          _loadHistory(refresh: true);
          _loadStats();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          const ThemeToggle(),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          if (_stats != null) _buildStatsCard(),
          _buildSearchBar(),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Lists', _stats!['total_lists']?.toString() ?? '0'),
            _buildStatItem('Items', _stats!['total_items']?.toString() ?? '0'),
            _buildStatItem(
                'Spent',
                _stats!['total_spent'] != null
                    ? '₪${_stats!['total_spent'].toStringAsFixed(2)}'
                    : '₪0.00'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search items...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onSubmitted: (_) => _loadHistory(refresh: true),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_historyItems.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadHistory(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_historyItems.isEmpty) {
      return const Center(
        child: Text('No purchase history found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadHistory(refresh: true),
      child: ListView.builder(
        itemCount: _historyItems.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _historyItems.length) {
            if (_isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              // Load more when reaching the end
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadHistory();
              });
              return const SizedBox.shrink();
            }
          }

          final item = _historyItems[index];
          return _buildHistoryTile(item);
        },
      ),
    );
  }

  Widget _buildHistoryTile(ShoppingListHistory item) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            item.totalItems.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.shoppingListName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${dateFormat.format(item.completedAt)} at ${timeFormat.format(item.completedAt)}'),
            Text('${item.totalItems} items completed'),
            if (item.completedByUsername != null)
              Text('Completed by: ${item.completedByUsername}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.totalPrice != null)
                  Text(
                    '₪${item.totalPrice!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'restore') {
                  _restoreShoppingList(item);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.restore),
                      SizedBox(width: 8),
                      Text('Restore List'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          ...item.items.map((historyItem) => ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                title: Text(historyItem.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (historyItem.description != null)
                      Text(
                        historyItem.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text('Qty: ${historyItem.quantity}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (historyItem.price != null)
                      Text(
                        historyItem.totalPriceDisplay,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () => _restoreItem(item, historyItem),
                      tooltip: 'Add to List',
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? selectedHouseholdId;
  final Function(DateTime?, DateTime?, int?) onApply;

  const _FilterDialog({
    this.startDate,
    this.endDate,
    this.selectedHouseholdId,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedHouseholdId;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedHouseholdId = widget.selectedHouseholdId;
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final households = authProvider.user?.households ?? [];

    return AlertDialog(
      title: const Text('Filter History'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Start Date'),
            subtitle: Text(_startDate != null
                ? DateFormat('MMM d, y').format(_startDate!)
                : 'Not set'),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(true),
            ),
          ),
          ListTile(
            title: const Text('End Date'),
            subtitle: Text(_endDate != null
                ? DateFormat('MMM d, y').format(_endDate!)
                : 'Not set'),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(false),
            ),
          ),
          if (households.isNotEmpty)
            DropdownButtonFormField<int?>(
              value: _selectedHouseholdId,
              decoration: const InputDecoration(
                labelText: 'Household',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Households'),
                ),
                ...households.map((household) => DropdownMenuItem(
                      value: household.id,
                      child: Text(household.name),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedHouseholdId = value;
                });
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _startDate = null;
              _endDate = null;
              _selectedHouseholdId = null;
            });
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_startDate, _endDate, _selectedHouseholdId);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _RestoreShoppingListDialog extends StatefulWidget {
  final List<ShoppingList> availableShoppingLists;
  final String originalName;

  const _RestoreShoppingListDialog({
    required this.availableShoppingLists,
    required this.originalName,
  });

  @override
  State<_RestoreShoppingListDialog> createState() =>
      _RestoreShoppingListDialogState();
}

class _RestoreShoppingListDialogState
    extends State<_RestoreShoppingListDialog> {
  int? _selectedListId;
  bool _createNew = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = '${widget.originalName} (Restored)';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restore Shopping List'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<bool>(
            title: const Text('Add to existing list'),
            value: false,
            groupValue: _createNew,
            onChanged: (value) => setState(() => _createNew = value!),
          ),
          if (!_createNew)
            DropdownButtonFormField<int>(
              value: _selectedListId,
              decoration: const InputDecoration(labelText: 'Select List'),
              items: widget.availableShoppingLists
                  .map(
                    (list) => DropdownMenuItem(
                      value: list.id,
                      child: Text(list.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedListId = value),
            ),
          RadioListTile<bool>(
            title: const Text('Create new list'),
            value: true,
            groupValue: _createNew,
            onChanged: (value) => setState(() => _createNew = value!),
          ),
          if (_createNew)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'List Name'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = <String, dynamic>{};
            if (_createNew) {
              result['targetListName'] = _nameController.text;
            } else {
              result['targetListId'] = _selectedListId;
            }
            Navigator.of(context).pop(result);
          },
          child: const Text('Restore'),
        ),
      ],
    );
  }
}

class _SelectShoppingListDialog extends StatelessWidget {
  final List<ShoppingList> availableShoppingLists;

  const _SelectShoppingListDialog({
    required this.availableShoppingLists,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Shopping List'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableShoppingLists.length,
          itemBuilder: (context, index) {
            final list = availableShoppingLists[index];
            return ListTile(
              title: Text(list.name),
              subtitle: Text('${list.items.length} items'),
              onTap: () => Navigator.of(context).pop(list),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
