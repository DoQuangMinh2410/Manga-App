// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ThemeProvider extends ChangeNotifier {
  final PreferencesService _prefsService;
  bool _isDarkMode = false;

  ThemeProvider(this._prefsService);

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    _isDarkMode = await _prefsService.isDarkMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefsService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    await _prefsService.setDarkMode(value);
    notifyListeners();
  }
}
