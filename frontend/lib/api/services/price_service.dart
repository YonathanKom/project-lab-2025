import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/price_comparison.dart';

class PriceService {
  final String baseUrl;

  PriceService(this.baseUrl);

  Future<ShoppingListPriceComparison> compareShoppingListPrices(
    int listId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/prices/shopping-lists/$listId/compare'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ShoppingListPriceComparison.fromJson(data);
    } else {
      throw Exception('Failed to compare prices: ${response.body}');
    }
  }
}
