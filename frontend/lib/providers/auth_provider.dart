import 'package:flutter/material.dart';
import '../api/services/auth_service.dart';
import '../utils/secure_storage.dart';

// User model class
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      householdId: json['household_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'household_id': householdId,
    };
  }
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
        _status = AuthStatus
            .unauthenticated; // User needs to login after registration
        notifyListeners();
        return true;
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
}
