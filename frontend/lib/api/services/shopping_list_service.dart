import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/shopping_list.dart';

class ShoppingListService {
  final String baseUrl;

  ShoppingListService({required this.baseUrl});

  Future<List<ShoppingList>> getShoppingLists(String token,
      {int? householdId}) async {
    try {
      String url = '$baseUrl/shopping-lists/';
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
        return data.map((item) => ShoppingList.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load shopping lists: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shopping lists: $e');
    }
  }

  Future<ShoppingList> getShoppingList(int listId, String token) async {
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
        throw Exception('Failed to load shopping list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shopping list: $e');
    }
  }

  Future<ShoppingList> createShoppingList(
    ShoppingListCreate shoppingListData,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shopping-lists/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(shoppingListData.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ShoppingList.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['detail'] ?? 'Failed to create shopping list');
      }
    } catch (e) {
      throw Exception('Error creating shopping list: $e');
    }
  }

  Future<ShoppingList> updateShoppingList(
    int listId,
    ShoppingListUpdate updateData,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/shopping-lists/$listId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData.toJson()),
      );

      if (response.statusCode == 200) {
        return ShoppingList.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['detail'] ?? 'Failed to update shopping list');
      }
    } catch (e) {
      throw Exception('Error updating shopping list: $e');
    }
  }

  Future<void> deleteShoppingList(int listId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/shopping-lists/$listId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['detail'] ?? 'Failed to delete shopping list');
      }
    } catch (e) {
      throw Exception('Error deleting shopping list: $e');
    }
  }
}
