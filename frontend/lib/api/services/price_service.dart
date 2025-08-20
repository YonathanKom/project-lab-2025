import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/price_comparison.dart';

class PriceService {
  final String baseUrl;

  PriceService(this.baseUrl);

  // Update existing method signature and implementation
  Future<ShoppingListPriceComparison> compareShoppingListPrices(
    int listId,
    String token, {
    double? userLat,
    double? userLon,
    double? radiusKm,
  }) async {
    final queryParams = <String, String>{};

    // Add location parameters if all are provided
    if (userLat != null && userLon != null && radiusKm != null) {
      queryParams['user_lat'] = userLat.toString();
      queryParams['user_lon'] = userLon.toString();
      queryParams['radius_km'] = radiusKm.toString();
    }

    final uri = Uri.parse('$baseUrl/prices/shopping-lists/$listId/compare')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(
      uri,
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
