import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Base URL for API calls
  final String baseUrl;

  // Constructor
  AuthService({required this.baseUrl});

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    int? householdId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          if (householdId != null) 'household_id': householdId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successful registration
        return {
          'success': true,
          'data': responseData,
          'message': 'Registration successful',
        };
      } else {
        // Failed registration with error message from server
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Registration failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      // Handle network or other errors
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login user (placeholder for future implementation)
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    // TODO: Implement login functionality
    throw UnimplementedError('Login functionality not implemented yet');
  }
}
