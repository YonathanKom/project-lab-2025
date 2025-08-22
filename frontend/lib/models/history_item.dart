// lib/models/history_item.dart

class ShoppingListHistory {
  final int id;
  final String shoppingListName;
  final int householdId;
  final DateTime completedAt;
  final int completedById;
  final String? completedByUsername;
  final List<HistoryShoppingItem> items;

  ShoppingListHistory({
    required this.id,
    required this.shoppingListName,
    required this.householdId,
    required this.completedAt,
    required this.completedById,
    this.completedByUsername,
    required this.items,
  });

  factory ShoppingListHistory.fromJson(Map<String, dynamic> json) {
    return ShoppingListHistory(
      id: json['id'],
      shoppingListName: json['shopping_list_name'],
      householdId: json['household_id'],
      completedAt: DateTime.parse(json['completed_at']),
      completedById: json['completed_by_id'],
      completedByUsername: json['completed_by_username'],
      items: (json['items'] as List)
          .map((item) => HistoryShoppingItem.fromJson(item))
          .toList(),
    );
  }

  int get totalItems => items.length;
  int get purchasedItems => items.where((item) => item.isPurchased).length;
  double get completionPercentage =>
      totalItems > 0 ? (purchasedItems / totalItems) * 100 : 0;

  double? get totalPrice {
    final prices = items
        .where((item) => item.price != null)
        .map((item) => item.totalPrice);
    return prices.isNotEmpty ? prices.reduce((a, b) => a + b) : null;
  }
}

class HistoryShoppingItem {
  final String name;
  final String? description;
  final double quantity;
  final String? itemCode;
  final double? price;
  final bool isPurchased;

  HistoryShoppingItem({
    required this.name,
    this.description,
    required this.quantity,
    this.itemCode,
    this.price,
    required this.isPurchased,
  });

  factory HistoryShoppingItem.fromJson(Map<String, dynamic> json) {
    return HistoryShoppingItem(
      name: json['name'],
      description: json['description'],
      quantity: (json['quantity'] as num).toDouble(),
      itemCode: json['item_code'],
      price: json['price']?.toDouble(),
      isPurchased: json['is_purchased'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'quantity': quantity,
      'item_code': itemCode,
      'price': price,
      'is_purchased': isPurchased,
    };
  }

  String get displayPrice =>
      price != null ? '₪${price!.toStringAsFixed(2)}' : 'N/A';

  double get totalPrice => price != null ? price! * quantity : 0;

  String get totalPriceDisplay =>
      price != null ? '₪${totalPrice.toStringAsFixed(2)}' : 'N/A';
}

// Keep the existing HistoryFilter for compatibility
class HistoryFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? householdId;
  final String? searchQuery;

  HistoryFilter({
    this.startDate,
    this.endDate,
    this.householdId,
    this.searchQuery,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (startDate != null) params['start_date'] = startDate!.toIso8601String();
    if (endDate != null) params['end_date'] = endDate!.toIso8601String();
    if (householdId != null) params['household_id'] = householdId!.toString();
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['search'] = searchQuery!;
    }
    return params;
  }
}

// Models for restore operations
class RestoreToList {
  final int? targetListId;
  final String? targetListName;

  RestoreToList({
    this.targetListId,
    this.targetListName,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (targetListId != null) json['target_list_id'] = targetListId;
    if (targetListName != null) json['target_list_name'] = targetListName;
    return json;
  }
}
