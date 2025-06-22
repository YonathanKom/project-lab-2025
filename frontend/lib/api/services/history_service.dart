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

    final uri =
        Uri.parse('$baseUrl/history').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
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

    final uri = Uri.parse('$baseUrl/history/stats')
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
