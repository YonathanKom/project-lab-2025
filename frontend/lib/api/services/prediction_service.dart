import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/prediction.dart';

class PredictionService {
  final String baseUrl;

  PredictionService(this.baseUrl);

  Future<PredictionsResponse> getPredictions({
    required String token,
    int? shoppingListId,
    int limit = 10,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      if (shoppingListId != null) 'shopping_list_id': shoppingListId.toString(),
    };

    final uri = Uri.parse('$baseUrl/predictions/predictions')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PredictionsResponse.fromJson(data);
    } else {
      throw Exception('Failed to get predictions: ${response.body}');
    }
  }
}
