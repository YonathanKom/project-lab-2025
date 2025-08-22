import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/shopping_list.dart';
import '../../models/history_item.dart';

class ShoppingListService {
  final String baseUrl;

  ShoppingListService(this.baseUrl);

  Future<List<ShoppingList>> getShoppingLists({
    required String token,
    int? householdId,
  }) async {
    try {
      String url = '$baseUrl/shopping-lists';
      if (householdId != null) {
        url += '?household_id=$householdId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ShoppingList.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shopping lists: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load shopping lists: $e');
    }
  }

  Future<ShoppingList> getShoppingList({
    required int listId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shopping-lists/$listId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return ShoppingList.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load shopping list: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load shopping list: $e');
    }
  }

  Future<ShoppingList> createShoppingList({
    required ShoppingListCreate listData,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shopping-lists'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(listData.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ShoppingList.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create shopping list: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create shopping list: $e');
    }
  }

  Future<ShoppingList> updateShoppingList({
    required int listId,
    required ShoppingListUpdate listData,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/shopping-lists/$listId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(listData.toJson()),
      );

      if (response.statusCode == 200) {
        return ShoppingList.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update shopping list: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update shopping list: $e');
    }
  }

  Future<void> deleteShoppingList({
    required int listId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/shopping-lists/$listId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete shopping list: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete shopping list: $e');
    }
  }

  // Shopping Item methods
  Future<ShoppingItem> createShoppingItem({
    required int listId,
    required Map<String, dynamic> itemData,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/items/$listId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(itemData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ShoppingItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create item: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  Future<ShoppingItem> updateShoppingItem({
    required int listId,
    required int itemId,
    required Map<String, dynamic> itemData,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/items/$listId/$itemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(itemData),
      );

      if (response.statusCode == 200) {
        return ShoppingItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update item: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  Future<void> deleteShoppingItem({
    required int listId,
    required int itemId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/items/$listId/$itemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete item: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  Future<ShoppingItem> toggleItemPurchased({
    required int listId,
    required int itemId,
    required bool isPurchased,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/items/$listId/$itemId/toggle'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'is_purchased': isPurchased}),
      );

      if (response.statusCode == 200) {
        return ShoppingItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to toggle item: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to toggle item: $e');
    }
  }

  Future<Map<String, dynamic>> completeShoppingList({
    required int listId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shopping-lists/$listId/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to complete shopping list: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to complete shopping list: $e');
    }
  }

  Future<Map<String, dynamic>> restoreFromHistory({
    required int historyId,
    required RestoreToList restoreData,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/history/$historyId/restore'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(restoreData.toJson()),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to restore from history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to restore from history: $e');
    }
  }

  Future<Map<String, dynamic>> restoreItemFromHistory({
    required int historyId,
    required String itemName,
    required int targetListId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl/history/$historyId/restore-item?item_name=${Uri.encodeComponent(itemName)}&target_list_id=$targetListId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to restore item from history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to restore item from history: $e');
    }
  }
}
