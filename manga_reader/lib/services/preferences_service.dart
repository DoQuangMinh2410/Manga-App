// lib/services/preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─── Theme Mode ──────────────────────────────────────────────────────────────
  Future<bool> isDarkMode() async {
    final p = await prefs;
    return p.getBool(AppConstants.keyThemeMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final p = await prefs;
    await p.setBool(AppConstants.keyThemeMode, value);
  }

  // ─── Onboarding ──────────────────────────────────────────────────────────────
  Future<bool> isOnboardingDone() async {
    final p = await prefs;
    return p.getBool(AppConstants.keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    final p = await prefs;
    await p.setBool(AppConstants.keyOnboardingDone, value);
  }

  // ─── Default View Mode ───────────────────────────────────────────────────────
  Future<String> getDefaultView() async {
    final p = await prefs;
    return p.getString(AppConstants.keyDefaultView) ?? AppConstants.viewGrid;
  }

  Future<void> setDefaultView(String view) async {
    final p = await prefs;
    await p.setString(AppConstants.keyDefaultView, view);
  }

  // ─── Reading Font Size ────────────────────────────────────────────────────────
  Future<double> getReadingFontSize() async {
    final p = await prefs;
    return p.getDouble(AppConstants.keyReadingFont) ?? 16.0;
  }

  Future<void> setReadingFontSize(double size) async {
    final p = await prefs;
    await p.setDouble(AppConstants.keyReadingFont, size);
  }

  // ─── Clear All ───────────────────────────────────────────────────────────────
  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
