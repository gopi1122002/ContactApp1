import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Light theme configuration
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[100],
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16.0),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      backgroundColor: Colors.grey[100],
    ).copyWith(
      secondary: Colors.blueAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black87,
      error: Colors.red,
    ),
  );

  // Dark theme configuration
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[900],
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16.0, color: Colors.white70),
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      backgroundColor: Colors.grey[900],
    ).copyWith(
      secondary: Colors.blueAccent[700],
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: Colors.grey[850],
      onSurface: Colors.white70,
      error: Colors.red[400],
    ),
  );
}