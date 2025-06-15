class ShoppingListPriceComparison {
  final int shoppingListId;
  final String shoppingListName;
  final int totalItems;
  final int comparedItems;
  final List<StoreComparison> storeComparisons;

  ShoppingListPriceComparison({
    required this.shoppingListId,
    required this.shoppingListName,
    required this.totalItems,
    required this.comparedItems,
    required this.storeComparisons,
  });

  factory ShoppingListPriceComparison.fromJson(Map<String, dynamic> json) {
    return ShoppingListPriceComparison(
      shoppingListId: json['shopping_list_id'],
      shoppingListName: json['shopping_list_name'],
      totalItems: json['total_items'],
      comparedItems: json['compared_items'],
      storeComparisons: (json['store_comparisons'] as List)
          .map((e) => StoreComparison.fromJson(e))
          .toList(),
    );
  }
}

class StoreComparison {
  final int storeId;
  final String storeName;
  final String chainName;
  final String? city;
  final double totalPrice;
  final int availableItems;
  final List<String> missingItems;
  final List<ItemPriceBreakdown> itemsBreakdown;

  StoreComparison({
    required this.storeId,
    required this.storeName,
    required this.chainName,
    this.city,
    required this.totalPrice,
    required this.availableItems,
    required this.missingItems,
    required this.itemsBreakdown,
  });

  factory StoreComparison.fromJson(Map<String, dynamic> json) {
    return StoreComparison(
      storeId: json['store_id'],
      storeName: json['store_name'],
      chainName: json['chain_name'],
      city: json['city'],
      totalPrice: json['total_price'].toDouble(),
      availableItems: json['available_items'],
      missingItems: List<String>.from(json['missing_items']),
      itemsBreakdown: (json['items_breakdown'] as List)
          .map((e) => ItemPriceBreakdown.fromJson(e))
          .toList(),
    );
  }

  double get availabilityPercentage => itemsBreakdown.isEmpty
      ? 0
      : (availableItems / itemsBreakdown.length) * 100;
}

class ItemPriceBreakdown {
  final String itemName;
  final int quantity;
  final double? unitPrice;
  final double? totalPrice;
  final bool isAvailable;

  ItemPriceBreakdown({
    required this.itemName,
    required this.quantity,
    this.unitPrice,
    this.totalPrice,
    required this.isAvailable,
  });

  factory ItemPriceBreakdown.fromJson(Map<String, dynamic> json) {
    return ItemPriceBreakdown(
      itemName: json['item_name'],
      quantity: json['quantity'],
      unitPrice: json['unit_price']?.toDouble(),
      totalPrice: json['total_price']?.toDouble(),
      isAvailable: json['is_available'],
    );
  }
}
