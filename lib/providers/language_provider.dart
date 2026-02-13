import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isFirstTime = true;
  static const String _languageKey = 'selected_language';
  static const String _firstTimeKey = 'is_first_time_language';

  Locale get locale => _locale;
  bool get isFirstTime => _isFirstTime;

  LanguageProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if it's the first time
    _isFirstTime = prefs.getBool(_firstTimeKey) ?? true;
    
    final String? languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    _isFirstTime = false;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    await prefs.setBool(_firstTimeKey, false);
  }
}
