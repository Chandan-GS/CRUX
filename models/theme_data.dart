import 'package:flutter/material.dart';

// 1. Define your color palette for LIGHT mode
class AppColorsLight {
  static const Color primary = Color(0xFFFFFFFF); // white
  static const Color secondary = Color(0xFF2C2C2C); // dark gray
  static const Color accent = Color(0xFFFF9A00); // orange
  static const Color background = Color(0xFFE7E7E7); // light gray
  static const Color text = Color(0xFF2C2C2C); // dark gray for text
  static const Color textOnPrimary = Color(0xFF2C2C2C); // text on white
  static const Color textOnSecondary = Color(0xFFFFFFFF); // text on dark gray
}

// 2. Define your color palette for DARK mode
class AppColorsDark {
  static const Color primary = Color(0xFF2C2C2C); // dark gray
  static const Color secondary = Color(0xFFE6E6E6); // light gray
  static const Color accent = Color(0xFFFF9A00); // orange
  static const Color background = Color(0xFF000000); // black
  static const Color text = Color(0xFFE6E6E6); // light gray for text
  static const Color textOnPrimary = Color(0xFFE6E6E6); // text on dark gray
  static const Color textOnSecondary = Color(0xFF2C2C2C); // text on light gray
}

class AppTheme {
  // 3. Define the LIGHT theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColorsLight.primary,
    scaffoldBackgroundColor: AppColorsLight.background,

    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.primary,
      onPrimary: AppColorsLight.textOnPrimary,
      secondary: AppColorsLight.secondary,
      onSecondary: AppColorsLight.textOnSecondary,
      tertiary: AppColorsLight.accent, // Using tertiary for the accent color
      onTertiary: AppColorsLight.textOnSecondary,
      surface: AppColorsLight.primary, // Cards, dialogs, etc.
      onSurface: Color(0xFF2C2C2C),
      background: AppColorsLight.background,
      onBackground: AppColorsLight.text,
      error: Colors.redAccent,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsLight.primary,
      foregroundColor: AppColorsLight.text,
      elevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: AppColorsLight.text,
      ),
    ),

    textTheme: const TextTheme(
      // Define text styles that will be used on the background
      bodyMedium: TextStyle(color: AppColorsLight.text),
      titleLarge: TextStyle(
        color: AppColorsLight.text,
        fontWeight: FontWeight.bold,
      ),
      // ... add other text styles as needed
    ).apply(bodyColor: AppColorsLight.text, displayColor: AppColorsLight.text),

    iconTheme: const IconThemeData(color: AppColorsLight.text, size: 24.0),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsLight.accent,
        foregroundColor: AppColorsLight.textOnSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),

    // Add other widget themes if needed
  );

  // 4. Define the DARK theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColorsDark.primary,
    scaffoldBackgroundColor: AppColorsDark.background,

    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.primary,
      onPrimary: AppColorsDark.textOnPrimary,
      secondary: AppColorsDark.secondary,
      onSecondary: AppColorsDark.textOnSecondary,
      tertiary: AppColorsDark.accent,
      onTertiary: AppColorsDark.textOnSecondary,
      surface: AppColorsDark.primary,
      onSurface: Color(0xFF2C2C2C),
      background: AppColorsDark.background,
      onBackground: AppColorsDark.text,
      error: Colors.redAccent,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsDark.primary,
      foregroundColor: AppColorsDark.text,
      elevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: AppColorsDark.text,
      ),
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColorsDark.text),
      titleLarge: TextStyle(
        color: AppColorsDark.text,
        fontWeight: FontWeight.bold,
      ),
      // ... add other text styles as needed
    ).apply(bodyColor: AppColorsDark.text, displayColor: AppColorsDark.text),

    iconTheme: const IconThemeData(color: AppColorsDark.text, size: 24.0),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.accent,
        foregroundColor: AppColorsDark.textOnSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),
    // Add other widget themes if needed
  );
}
