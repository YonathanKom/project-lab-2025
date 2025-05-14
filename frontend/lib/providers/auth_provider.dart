import 'package:flutter/material.dart';
import '../api/services/auth_service.dart';

// User model to store authenticated user data
class User {
  final int id;
  final String username;
  final String email;
  final int? householdId;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.householdId,
  });

  // Create User from API response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      householdId: json['household_id'],
    );
  }
}

// Authentication states
enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  // Dependencies
  final AuthService _authService;

  // State variables
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isRegistering = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isRegistering => _isRegistering;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Constructor
  AuthProvider({required AuthService authService}) : _authService = authService;

  // Register a new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    int? householdId,
  }) async {
    try {
      // Update state to registering
      _status = AuthStatus.authenticating;
      _isRegistering = true;
      _errorMessage = null;
      notifyListeners();

      // Call registration API
      final result = await _authService.register(
        username: username,
        email: email,
        password: password,
        householdId: householdId,
      );

      // Handle response
      if (result['success']) {
        // On success, create user object from response data
        _user = User.fromJson(result['data']);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        // On failure, update error state
        _status = AuthStatus.error;
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Handle exceptions
      _status = AuthStatus.error;
      _errorMessage = 'Registration error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  // Reset error state
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Logout user
  void logout() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
