import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/shopping_lists/shopping_lists_screen.dart';
import '../screens/items/items_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/help/help_screen.dart';
import '../screens/about/about_screen.dart';

class Routes {
  // Route constants
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String shoppingLists = '/shopping-lists';
  static const String items = '/items';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String about = '/about';

  // Get all routes mapping
  static Map<String, Widget Function(BuildContext)> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      dashboard: (context) => const DashboardScreen(),
      shoppingLists: (context) => const ShoppingListsScreen(),
      items: (context) => const ItemsScreen(),
      history: (context) => const HistoryScreen(),
      settings: (context) => const SettingsScreen(),
      help: (context) => const HelpScreen(),
      about: (context) => const AboutScreen(),
    };
  }
}
