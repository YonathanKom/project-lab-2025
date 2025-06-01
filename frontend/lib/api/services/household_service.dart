// api/services/household_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/household.dart';

class HouseholdService {
  final String baseUrl;

  HouseholdService(this.baseUrl);

  // Create a new household
  Future<Map<String, dynamic>> createHousehold(
      String name, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/households/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(HouseholdCreate(name: name).toJson()),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to create household: $e');
    }
  }

  // Get all user's households
  Future<Map<String, dynamic>> getUserHouseholds(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/households/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get user households: $e');
    }
  }

  // Get specific household details
  Future<Map<String, dynamic>> getHousehold(
      int householdId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/households/$householdId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get household: $e');
    }
  }

  // Update household (admin only)
  Future<Map<String, dynamic>> updateHousehold(
      int householdId, String name, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/households/$householdId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(HouseholdUpdate(name: name).toJson()),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update household: $e');
    }
  }

  // Join household by ID
  Future<Map<String, dynamic>> joinHousehold(
      int householdId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/households/$householdId/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to join household: $e');
    }
  }

  // Leave household
  Future<Map<String, dynamic>> leaveHousehold(
      int householdId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/households/$householdId/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to leave household: $e');
    }
  }

  // Remove member from household (admin only)
  Future<Map<String, dynamic>> removeMember(
      int householdId, int userId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/households/$householdId/members/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // Send invitation to join household (admin only)
  Future<Map<String, dynamic>> inviteToHousehold(
      int householdId, String email, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/households/$householdId/invite'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(InvitationCreate(email: email).toJson()),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to send invitation: $e');
    }
  }

  // Get received invitations
  Future<Map<String, dynamic>> getReceivedInvitations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/households/invitations/received'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get received invitations: $e');
    }
  }

  // Get sent invitations
  Future<Map<String, dynamic>> getSentInvitations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/households/invitations/sent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get sent invitations: $e');
    }
  }

  // Accept invitation
  Future<Map<String, dynamic>> acceptInvitation(
      int invitationId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/households/invitations/$invitationId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  // Reject invitation
  Future<Map<String, dynamic>> rejectInvitation(
      int invitationId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/households/invitations/$invitationId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to reject invitation: $e');
    }
  }

  // Cancel sent invitation (admin only)
  Future<Map<String, dynamic>> cancelInvitation(
      int invitationId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/households/invitations/$invitationId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to cancel invitation: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'error': data['detail'] ?? 'Unknown error occurred',
        'status_code': response.statusCode,
      };
    }
  }
}
