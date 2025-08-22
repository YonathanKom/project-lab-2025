import 'package:flutter/material.dart';
import '../api/services/auth_service.dart';
import '../models/household.dart';
import '../utils/secure_storage.dart';

// User model class
class User {
  final int id;
  final String username;
  final String email;
  final List<Household> households;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.households,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawHouseholds = json['households'];
    final householdsList = (rawHouseholds as List<dynamic>?) ?? [];
    final households =
        householdsList.map((h) => Household.fromJson(h)).toList();

    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      households: households,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'households': households.map((h) => h.toJson()).toList(),
    };
  }

  /// Helper to get a list of household IDs if needed
  List<int> get householdIds => households.map((h) => h.id).toList();
}

// Auth status enum
enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

// Main provider class
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isRegistering = false;
  String? _token;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isRegistering => _isRegistering;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get token => _token;

  AuthProvider({required AuthService authService})
      : _authService = authService {
    _checkAuthentication();
  }

  // Check if user is already authenticated (token exists and is valid)
  Future<void> _checkAuthentication() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final storedToken = await SecureStorage.getToken();
      if (storedToken != null) {
        final isValid = await _authService.verifyToken(storedToken);
        if (isValid) {
          _token = storedToken;
          await _loadUserProfile();
          return;
        }
      }

      // If we reach here, token is invalid or doesn't exist
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Load user profile using stored token
  Future<void> _loadUserProfile() async {
    if (_token == null) return;

    final response = await _authService.getUserProfile(_token!);

    if (response['success']) {
      _user = User.fromJson(response['data']);
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
      await SecureStorage.deleteToken();
      _token = null;
    }

    notifyListeners();
  }

  // User registration
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    int? householdId,
  }) async {
    _isRegistering = true;
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
        householdId: householdId,
      );

      _isRegistering = false;

      if (response['success']) {
        final bool loginSuccess =
            await login(username: username, password: password);
        return loginSuccess;
      } else {
        _errorMessage = response['message'];
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isRegistering = false;
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // User login
  Future<bool> login(
      {required String username, required String password}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        username: username,
        password: password,
      );

      if (response['success']) {
        _token = response['token'];

        // Store token securely
        await SecureStorage.saveToken(_token!);

        // Load user profile
        await _loadUserProfile();

        return true;
      } else {
        _errorMessage = response['message'];
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // User logout
  Future<void> logout() async {
    await SecureStorage.deleteToken();
    await SecureStorage.deleteUserData();
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Refresh user data from server
  Future<void> refreshUserData() async {
    if (_token == null) {
      _errorMessage = 'No authentication token available';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final response = await _authService.getUserProfile(_token!);

      if (response['success']) {
        _user = User.fromJson(response['data']);
        // Clear any previous errors on successful refresh
        _errorMessage = null;
        if (_status != AuthStatus.authenticated) {
          _status = AuthStatus.authenticated;
        }
        notifyListeners();
      } else {
        // Server returned error response
        _errorMessage = response['message'] ?? 'Failed to refresh user data';

        // If it's an authentication error, logout the user
        if (response['message']?.toLowerCase().contains('token') == true ||
            response['message']?.toLowerCase().contains('unauthorized') ==
                true ||
            response['message']?.toLowerCase().contains('expired') == true) {
          await logout();
        } else {
          _status = AuthStatus.error;
          notifyListeners();
        }
      }
    } catch (e) {
      // Network or parsing error
      _errorMessage = 'Network error: Unable to refresh user data';
      _status = AuthStatus.error;
      notifyListeners();
    }
  }
}
