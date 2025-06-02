class ShoppingList {
  final int id;
  final String name;
  final int householdId;
  final int ownerId;
  final DateTime createdAt;
  final List<ShoppingItem> items;

  ShoppingList({
    required this.id,
    required this.name,
    required this.householdId,
    required this.ownerId,
    required this.createdAt,
    this.items = const [],
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      householdId: json['household_id'],
      ownerId: json['owner_id'],
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ShoppingItem.fromJson(item))
              .toList() ??
          [],
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

  ShoppingListUpdate({this.name});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    return data;
  }
}

class ShoppingItem {
  final int id;
  final String name;
  final String? description;
  final int quantity;
  final bool isPurchased;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    this.description,
    required this.quantity,
    required this.isPurchased,
    required this.createdAt,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      quantity: json['quantity'] ?? 1,
      isPurchased: json['is_purchased'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
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
    };
  }
}
