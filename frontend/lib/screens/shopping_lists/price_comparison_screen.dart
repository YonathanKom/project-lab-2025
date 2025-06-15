import 'package:fastflutter/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shopping_list.dart';
import '../../models/price_comparison.dart';
import '../../api/services/price_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/theme_toggle.dart';

class PriceComparisonScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const PriceComparisonScreen({
    super.key,
    required this.shoppingList,
  });

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  late PriceService _priceService;
  ShoppingListPriceComparison? _comparison;
  bool _isLoading = true;
  String? _errorMessage;
  int? _expandedStoreIndex;

  @override
  void initState() {
    super.initState();
    _priceService = PriceService(baseUrl);
    _loadPriceComparison();
  }

  Future<void> _loadPriceComparison() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      final comparison = await _priceService.compareShoppingListPrices(
        widget.shoppingList.id,
        token,
      );

      setState(() {
        _comparison = comparison;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Price Comparison'),
        actions: const [ThemeToggle()],
      ),
      drawer: const AppDrawer(),
      body: _buildBody(),
    );
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
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPriceComparison,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_comparison == null || _comparison!.storeComparisons.isEmpty) {
      return const Center(
        child: Text('No price comparisons available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPriceComparison,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          Text(
            'Store Comparisons',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          ..._comparison!.storeComparisons.asMap().entries.map((entry) {
            final index = entry.key;
            final store = entry.value;
            final isExpanded = _expandedStoreIndex == index;
            final isCheapest = index == 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isCheapest ? 4 : 1,
              color: isCheapest
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCheapest
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      store.chainName,
                      style: TextStyle(
                        fontWeight: isCheapest ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${store.storeName}${store.city != null ? ' - ${store.city}' : ''}'),
                        const SizedBox(height: 4),
                        _buildAvailabilityIndicator(store),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₪${store.totalPrice.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isCheapest
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                        ),
                        if (isCheapest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'BEST PRICE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _expandedStoreIndex = isExpanded ? null : index;
                      });
                    },
                  ),
                  if (isExpanded) _buildItemsBreakdown(store),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.shoppingList.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total Items', _comparison!.totalItems.toString()),
                _buildStat(
                    'Compared Items', _comparison!.comparedItems.toString()),
                _buildStat(
                    'Stores', _comparison!.storeComparisons.length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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

  Widget _buildAvailabilityIndicator(StoreComparison store) {
    final percentage = store.availabilityPercentage;
    final color = percentage >= 80
        ? Colors.green
        : percentage >= 50
            ? Colors.orange
            : Colors.red;

    return Row(
      children: [
        Container(
          width: 100,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Theme.of(context).dividerColor,
          ),
          child: FractionallySizedBox(
            widthFactor: percentage / 100,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${store.availableItems}/${store.itemsBreakdown.length} items',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildItemsBreakdown(StoreComparison store) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (store.missingItems.isNotEmpty) ...[
            Text(
              'Missing Items (${store.missingItems.length}):',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: store.missingItems
                  .map((item) => Chip(
                        label: Text(item, style: const TextStyle(fontSize: 12)),
                        backgroundColor:
                            Theme.of(context).colorScheme.errorContainer,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Price Breakdown:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...store.itemsBreakdown.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.itemName} (×${item.quantity})',
                        style: TextStyle(
                          decoration: item.isAvailable
                              ? null
                              : TextDecoration.lineThrough,
                          color: item.isAvailable
                              ? null
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                    if (item.totalPrice != null)
                      Text(
                        '₪${item.totalPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.isAvailable
                              ? null
                              : Theme.of(context).disabledColor,
                        ),
                      )
                    else
                      Text(
                        'N/A',
                        style:
                            TextStyle(color: Theme.of(context).disabledColor),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
