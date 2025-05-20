import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
// Import other screens here as they are created

class Routes {
  // Route names
  static const String login = '/login';
  static const String register = '/register';
  static const dashboard = '/dashboard';
  // Add more route names as needed

  // Route mapping
  static Map<String, Widget Function(BuildContext)> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      dashboard: (context) => const DashboardScreen(),
      // Add other routes as they are created
      // Example: home: (context) => const HomeScreen(),
    };
  }
}
