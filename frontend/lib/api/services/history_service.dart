// lib/api/services/history_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/history_item.dart';

class HistoryService {
  final String baseUrl;

  HistoryService(this.baseUrl);

  Future<List<HistoryItem>> getHistory({
    required String token,
    HistoryFilter? filter,
    int? skip,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};

    if (filter != null) {
      queryParams.addAll(filter.toQueryParams());
    }
    if (skip != null) queryParams['skip'] = skip.toString();
    if (limit != null) queryParams['limit'] = limit.toString();

    // Debug: Check query parameters
    print('DEBUG: HistoryService query params: $queryParams');

    final uri = Uri.parse('$baseUrl/history/history')
        .replace(queryParameters: queryParams);

    // Debug: Check final URI
    print('DEBUG: HistoryService URI: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Debug: Check response
    print('DEBUG: HistoryService response status: ${response.statusCode}');
    print('DEBUG: HistoryService response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Debug: Check parsed data
      print('DEBUG: HistoryService parsed data type: ${data.runtimeType}');
      print(
          'DEBUG: HistoryService first item (if any): ${data.isNotEmpty ? data.first : 'empty'}');

      return data.map((json) => HistoryItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getHistoryStats({
    required String token,
    HistoryFilter? filter,
  }) async {
    final queryParams = <String, dynamic>{};

    if (filter != null) {
      queryParams.addAll(filter.toQueryParams());
    }

    final uri = Uri.parse('$baseUrl/history/history/stats')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load history stats: ${response.body}');
    }
  }
}
