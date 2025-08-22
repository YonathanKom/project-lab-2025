class ShoppingList {
  final int id;
  final String name;
  final int householdId;
  final int ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ShoppingItem> items;

  ShoppingList({
    required this.id,
    required this.name,
    required this.householdId,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      householdId: json['household_id'],
      ownerId: json['owner_id'],
      createdAt: DateTime.parse(json['created_at']),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => ShoppingItem.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'household_id': householdId,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class ShoppingListCreate {
  final String name;
  final int householdId;

  ShoppingListCreate({
    required this.name,
    required this.householdId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'household_id': householdId,
    };
  }
}

class ShoppingListUpdate {
  final String? name;

  ShoppingListUpdate({
    this.name,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    return json;
  }
}

class ShoppingItem {
  final int id;
  final String name;
  final String? description;
  final double quantity;
  final bool isPurchased;
  final DateTime createdAt;
  final String? itemCode;
  final double? price;
  final String? addedByUsername;
  final String? purchasedByUsername;

  ShoppingItem({
    required this.id,
    required this.name,
    this.description,
    required this.quantity,
    required this.isPurchased,
    required this.createdAt,
    this.itemCode,
    this.price,
    this.addedByUsername,
    this.purchasedByUsername,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      quantity: (json['quantity'] as num).toDouble(),
      isPurchased: json['is_purchased'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      itemCode: json['item_code'],
      price: json['price']?.toDouble(),
      addedByUsername: json['added_by_username'],
      purchasedByUsername: json['purchased_by_username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'is_purchased': isPurchased,
      'created_at': createdAt.toIso8601String(),
      'item_code': itemCode,
      'price': price,
      'added_by_username': addedByUsername,
      'purchased_by_username': purchasedByUsername,
    };
  }
}
