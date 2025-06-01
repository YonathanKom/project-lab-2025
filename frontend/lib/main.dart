import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'api/services/auth_service.dart';
import 'utils/constants.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Create theme provider
  final themeProvider = ThemeProvider();

  // Create auth service
  final authService = AuthService(baseUrl: baseUrl);

  // Create auth provider
  final authProvider = AuthProvider(authService: authService);

  // Run app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const MyApp(),
    ),
  );
}
