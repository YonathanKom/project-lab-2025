import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/catalog_item.dart';

class ItemService {
  final String baseUrl;

  ItemService(this.baseUrl);

  Future<List<CatalogItem>> searchItems({
    required String token,
    String? query,
    String? chainId,
    String? storeId,
    double? minPrice,
    double? maxPrice,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (chainId != null && chainId.isNotEmpty) {
        queryParams['chain_id'] = chainId;
      }
      if (storeId != null && storeId.isNotEmpty) {
        queryParams['store_id'] = storeId;
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }

      final uri = Uri.parse('$baseUrl/prices/items/search')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => CatalogItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search items: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to search items: $e');
    }
  }

  Future<CatalogItem> getItem({
    required String itemCode,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/prices/items/$itemCode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return CatalogItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get item: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get item: $e');
    }
  }

  Future<PriceComparison> compareItemPrices({
    required String itemCode,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/prices/items/$itemCode/compare'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return PriceComparison.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to compare prices: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to compare prices: $e');
    }
  }

  Future<List<Chain>> getChains({
    required String token,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/prices/chains?skip=$skip&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((chain) => Chain.fromJson(chain)).toList();
      } else {
        throw Exception('Failed to get chains: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get chains: $e');
    }
  }

  Future<List<Store>> getStores({
    required String token,
    String? chainId,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (chainId != null && chainId.isNotEmpty) {
        queryParams['chain_id'] = chainId;
      }

      final uri = Uri.parse('$baseUrl/prices/stores')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((store) => Store.fromJson(store)).toList();
      } else {
        throw Exception('Failed to get stores: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get stores: $e');
    }
  }
}
