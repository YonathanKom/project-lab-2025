import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration with consistent color palette and typography.
class AppTheme {
  /// Primary swatch colors
  static const Color primaryColor = Color(0xFF0077B6);
  static const Color primaryLight = Color(0xFF48CAE4);
  static const Color primaryDark = Color(0xFF023E8A);

  /// Secondary swatch colors
  static const Color secondaryColor = Color(0xFFFFB703);
  static const Color secondaryLight = Color(0xFFFDC43F);
  static const Color secondaryDark = Color(0xFFD68400);

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Text colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFBDBDBD);

  /// Accent colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  /// Font family
  static String fontFamily = 'Poppins';

  /// Gets the application theme
  static ThemeData lightTheme() {
    return _getTheme(Brightness.light);
  }

  /// Gets the dark theme
  static ThemeData darkTheme() {
    return _getTheme(Brightness.dark);
  }

  // Helper method to get theme based on brightness
  static ThemeData _getTheme(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      primaryColorLight: primaryLight,
      primaryColorDark: primaryDark,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.black,
        error: error,
        onError: Colors.white,
        surface: isLight ? surfaceLight : surfaceDark,
        onSurface: isLight ? textPrimaryLight : textPrimaryDark,
      ),
      scaffoldBackgroundColor: isLight ? surfaceLight : surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: isLight ? surfaceLight : surfaceDark,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      iconTheme: IconThemeData(
        color: isLight ? textPrimaryLight : textPrimaryDark,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.white, // Active tab label/icon color
        unselectedLabelColor: Colors.white70, // Inactive tab label/icon
        indicatorColor: Colors.white, // Underline color
      ),
      textTheme: _getTextTheme(brightness),
      fontFamily: fontFamily,
    );
  }

  /// Creates text theme with consistent typography
  static TextTheme _getTextTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color textColor = isDark ? textPrimaryDark : textPrimaryLight;

    // Using Google Fonts
    return GoogleFonts.getTextTheme(
      fontFamily,
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 96,
          fontWeight: FontWeight.w300,
          color: textColor,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 60,
          fontWeight: FontWeight.w300,
          color: textColor,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        headlineLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.25,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isDark ? textSecondaryDark : textSecondaryLight,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 1.25,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.4,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
