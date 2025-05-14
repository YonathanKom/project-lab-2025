import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'api/services/auth_service.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Create theme provider
  final themeProvider = ThemeProvider();

  // Create auth service
  final authService = AuthService(baseUrl: 'http://10.0.2.2:8000/api/v1');

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
