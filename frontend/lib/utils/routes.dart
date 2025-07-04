import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/household/household_screen.dart';
import '../screens/items/add_edit_item_screen.dart';
import '../screens/shopping_lists/shopping_list_details_screen.dart';
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
  static const String household = '/household';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String about = '/about';
  static const String shoppingListDetails = '/shopping-list-details';
  static const String addEditItem = '/add-edit-item';
  static const String priceComparison = '/price-comparison';

  // Get all routes mapping
  static Map<String, Widget Function(BuildContext)> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      dashboard: (context) => const DashboardScreen(),
      shoppingLists: (context) => const ShoppingListsScreen(),
      items: (context) => const ItemsScreen(),
      history: (context) => const HistoryScreen(),
      household: (context) => const HouseholdScreen(),
      settings: (context) => const SettingsScreen(),
      help: (context) => const HelpScreen(),
      about: (context) => const AboutScreen(),
      Routes.shoppingListDetails: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
        return ShoppingListDetailsScreen(
          shoppingList: args['shoppingList'] as ShoppingList,
        );
      },
      Routes.addEditItem: (context) => AddEditItemScreen(
            shoppingListId: ModalRoute.of(context)!.settings.arguments as int,
          ),
    };
  }
}
