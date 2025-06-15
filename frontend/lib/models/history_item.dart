// lib/models/history_item.dart

class HistoryItem {
  final int id;
  final String itemName;
  final String? itemCode;
  final int quantity;
  final double? price;
  final DateTime purchasedAt;
  final String purchasedBy;
  final String shoppingListName;
  final int shoppingListId;
  final String? storeName;
  final String? chainName;

  HistoryItem({
    required this.id,
    required this.itemName,
    this.itemCode,
    required this.quantity,
    this.price,
    required this.purchasedAt,
    required this.purchasedBy,
    required this.shoppingListName,
    required this.shoppingListId,
    this.storeName,
    this.chainName,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      itemName: json['item_name'],
      itemCode: json['item_code'],
      quantity: json['quantity'],
      price: json['price']?.toDouble(),
      purchasedAt: DateTime.parse(json['purchased_at']),
      purchasedBy: json['purchased_by'],
      shoppingListName: json['shopping_list_name'],
      shoppingListId: json['shopping_list_id'],
      storeName: json['store_name'],
      chainName: json['chain_name'],
    );
  }

  String get displayPrice =>
      price != null ? '₪${price!.toStringAsFixed(2)}' : 'N/A';

  String get totalPrice =>
      price != null ? '₪${(price! * quantity).toStringAsFixed(2)}' : 'N/A';
}

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
