// lib/screens/history/history_screen.dart

import 'package:fastflutter/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/theme_toggle.dart';
import '../../providers/auth_provider.dart';
import '../../models/history_item.dart';
import '../../api/services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryService _historyService;
  final List<HistoryItem> _historyItems = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  // Filter controls
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedHouseholdId;
  final TextEditingController _searchController = TextEditingController();

  // Stats
  Map<String, dynamic>? _stats;

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _historyService = HistoryService(baseUrl);
    _loadHistory();
    _loadStats();
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

      // Debug: Check auth data
      print('DEBUG: Token exists: ${token != null}');
      print('DEBUG: User: ${authProvider.user}');
      print('DEBUG: User households: ${authProvider.user?.households}');
      print(
          'DEBUG: User households type: ${authProvider.user?.households.runtimeType}');

      if (token == null) {
        throw Exception('No authentication token');
      }

      // Debug: Check filter values
      print('DEBUG: Selected household ID: $_selectedHouseholdId');
      print(
          'DEBUG: Selected household ID type: ${_selectedHouseholdId.runtimeType}');
      print('DEBUG: Start date: $_startDate');
      print('DEBUG: End date: $_endDate');
      print('DEBUG: Search query: ${_searchController.text}');

      final filter = HistoryFilter(
        startDate: _startDate,
        endDate: _endDate,
        householdId: _selectedHouseholdId,
        searchQuery: _searchController.text,
      );

      // Debug: Check filter object
      print('DEBUG: Filter object created');
      print('DEBUG: Filter query params: ${filter.toQueryParams()}');

      final items = await _historyService.getHistory(
        token: token,
        filter: filter,
        skip: _currentPage * _pageSize,
        limit: _pageSize,
      );

      // Debug: Check response
      print('DEBUG: Items received: ${items.length}');
      print('DEBUG: Items type: ${items.runtimeType}');

      setState(() {
        _historyItems.addAll(items);
        _currentPage++;
        _hasMore = items.length == _pageSize;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      // Debug: Enhanced error logging
      print('DEBUG: Error in _loadHistory: $e');
      print('DEBUG: Stack trace: $stackTrace');

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
            _buildStatItem(
                'Total Items', _stats!['total_items']?.toString() ?? '0'),
            _buildStatItem('Total Spent',
                '₪${_stats!['total_spent']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildStatItem('Avg Price',
                '₪${_stats!['avg_price']?.toStringAsFixed(2) ?? '0.00'}'),
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

  Widget _buildHistoryTile(HistoryItem item) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            item.quantity.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.itemName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${dateFormat.format(item.purchasedAt)} at ${timeFormat.format(item.purchasedAt)}'),
            Text('From: ${item.shoppingListName}'),
            if (item.storeName != null || item.chainName != null)
              Text('Store: ${item.chainName ?? ''} ${item.storeName ?? ''}'
                  .trim()),
            Text('By: ${item.purchasedBy}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.totalPrice,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (item.price != null)
              Text(
                '${item.displayPrice} each',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        isThreeLine: true,
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
