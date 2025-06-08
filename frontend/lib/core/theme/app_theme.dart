import 'package:flutter/material.dart';

/// Theme configuration for the app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();
  
  // Primary colors
  static const Color primaryColor = Color(0xFF6A4C93);
  static const Color primaryLightColor = Color(0xFF8A6CB3);
  static const Color primaryDarkColor = Color(0xFF4A2C73);
  
  // Secondary colors
  static const Color secondaryColor = Color(0xFF00B4D8);
  static const Color secondaryLightColor = Color(0xFF20D4F8);
  static const Color secondaryDarkColor = Color(0xFF0094B8);
  
  // Background colors
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimaryColor = Color(0xFF333333);
  static const Color textSecondaryColor = Color(0xFF666666);
  static const Color textMutedColor = Color(0xFF999999);
  
  // Accent colors
  static const Color accentRed = Color(0xFFF25F5C);
  static const Color accentGreen = Color(0xFF4CB963);
  static const Color accentOrange = Color(0xFFFF9F1C);
  static const Color accentPurple = Color(0xFF8F3985);
  
  // Utility colors
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);
  static const Color infoColor = Color(0xFF1976D2);
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  // Light theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    primaryColorLight: primaryLightColor,
    primaryColorDark: primaryDarkColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryColor,
      onBackground: textPrimaryColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      buttonColor: primaryColor,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      disabledColor: Colors.grey[300],
      selectedColor: primaryColor.withOpacity(0.2),
      secondarySelectedColor: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        color: Colors.grey[800],
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
      ),
      brightness: Brightness.light,
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 24,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textPrimaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textPrimaryColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textSecondaryColor,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      type: BottomNavigationBarType.fixed,
    ),
  );
  
  // Dark theme (can be implemented later)
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    // Dark theme configuration
  );
  
  // Get theme based on brightness
  static ThemeData getTheme({Brightness brightness = Brightness.light}) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }
  
  // Custom color utilities
  
  /// Generate a color palette from a base color
  static List<Color> generatePalette(Color baseColor, {int steps = 5}) {
    final List<Color> palette = [];
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    
    // Generate lighter variants
    for (int i = 1; i <= steps; i++) {
      final double lightness = hslColor.lightness + (i * (1 - hslColor.lightness) / (steps + 1));
      palette.add(hslColor.withLightness(lightness).toColor());
    }
    
    // Add base color
    palette.add(baseColor);
    
    // Generate darker variants
    for (int i = 1; i <= steps; i++) {
      final double lightness = hslColor.lightness - (i * hslColor.lightness / (steps + 1));
      palette.add(hslColor.withLightness(lightness).toColor());
    }
    
    return palette;
  }
  
  /// Create a gradient from a base color
  static LinearGradient createGradient(Color baseColor, {bool reversed = false}) {
    final List<Color> colors = [
      baseColor,
      HSLColor.fromColor(baseColor).withLightness(0.8).toColor(),
    ];
    
    return LinearGradient(
      colors: reversed ? colors.reversed.toList() : colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
