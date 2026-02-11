import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Update UI immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  // Branding Colors
  static const Color accentColor = Color(0xFFFF8700); // Lime/Neon Yellow
  
  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF1E1E2C);
  static const Color darkSecondary = Color(0xFF2D2D44);
  static const Color darkBackground = Color(0xFF121212);
  
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFFF5F5F7);
  static const Color lightBackground = Color(0xFFFAFAFA);

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: darkPrimary,
    colorScheme: const ColorScheme.dark(
      primary: accentColor,
      surface: darkSecondary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSecondary,
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.white38,
    ),
  );

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: lightPrimary,
    colorScheme: const ColorScheme.light(
      primary: Colors.black, // Or another contrast color
      secondary: accentColor,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black, // Or brand color
      unselectedItemColor: Colors.black38,
    ),
  );
}
