import 'package:flutter/material.dart';

class AppTheme {
  // Primary Brand Colors
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A47A3);
  static const Color primaryLight = Color(0xFF9B97FF);

  // Accent Colors
  static const Color accentOrange = Color(0xFFFF6B6B);
  static const Color accentGreen = Color(0xFF4ECDC4);
  static const Color accentYellow = Color(0xFFFFE66D);
  static const Color accentBlue = Color(0xFF4A90E2);

  // Neutral Colors
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textDark = Color(0xFF2D3436);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF74798C);

  // Semantic Colors
  static const Color success = Color(0xFF51CF66);
  static const Color warning = Color(0xFFFFD93D);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF4A90E2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF51CF66), Color(0xFF3BB54A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient energyGradient = LinearGradient(
    colors: [accentOrange, accentYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calmGradient = LinearGradient(
    colors: [accentBlue, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: lightBackground,

    colorScheme: ColorScheme.light(
      primary: primaryPurple,
      secondary: accentOrange,
      surface: lightCard,
      background: lightBackground,
      error: error,
      onPrimary: textLight,
      onSecondary: textLight,
      onSurface: textDark,
      onBackground: textDark,
      onError: textLight,
    ),

    cardTheme: CardTheme(
      color: lightCard,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textDark),
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: textLight,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryPurple,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textGrey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textGrey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textDark,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textGrey,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: primaryLight.withOpacity(0.2),
      deleteIconColor: primaryPurple,
      labelStyle: TextStyle(color: primaryPurple),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryPurple,
      foregroundColor: textLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: darkBackground,

    colorScheme: ColorScheme.dark(
      primary: primaryPurple,
      secondary: accentOrange,
      surface: darkCard,
      background: darkBackground,
      error: error,
      onPrimary: textLight,
      onSecondary: textLight,
      onSurface: textLight,
      onBackground: textLight,
      onError: textLight,
    ),

    cardTheme: CardTheme(
      color: darkCard,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textLight),
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: textLight,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textLight.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textLight.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textLight,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textLight,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textLight,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textLight,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textLight,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textLight,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textGrey,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: primaryPurple.withOpacity(0.2),
      deleteIconColor: primaryLight,
      labelStyle: TextStyle(color: primaryLight),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryPurple,
      foregroundColor: textLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Custom Box Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 30,
      offset: Offset(0, 12),
    ),
  ];

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Border Radius
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(24));

  // Spacing
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double space2XL = 48;
}
