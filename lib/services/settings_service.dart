import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persystowane ustawienia aplikacji (motyw, kolor, jednostki, powiadomienia).
/// Używa ChangeNotifier do poinformowania drzewa widgetów o zmianach.
class SettingsService extends ChangeNotifier {
  static const _keyTheme   = 'settings_theme';   // 'dark' | 'light' | 'system'
  static const _keyAccent  = 'settings_accent';  // int ARGB
  static const _keyUnits   = 'settings_units';   // 'kg' | 'lbs'
  static const _keyNotifs  = 'settings_notifs';  // bool

  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  SettingsService._();

  // Wartości domyślne
  ThemeMode _themeMode = ThemeMode.dark;
  Color     _accentColor = const Color(0xFFE94560);
  String    _units = 'kg';
  bool      _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  Color     get accentColor => _accentColor;
  String    get units => _units;
  bool      get notificationsEnabled => _notificationsEnabled;

  // ── Inicjalizacja ────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_keyTheme) ?? 'dark';
    _themeMode = _parseTheme(themeStr);

    final accentInt = prefs.getInt(_keyAccent);
    if (accentInt != null) _accentColor = Color(accentInt);

    _units = prefs.getString(_keyUnits) ?? 'kg';
    _notificationsEnabled = prefs.getBool(_keyNotifs) ?? true;
  }

  // ── Settery z persystencją ───────────────────────────────
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, _themeName(mode));
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccent, color.toARGB32());
    notifyListeners();
  }

  Future<void> setUnits(String units) async {
    _units = units;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUnits, units);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifs, enabled);
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────
  static ThemeMode _parseTheme(String s) {
    switch (s) {
      case 'light':  return ThemeMode.light;
      case 'system': return ThemeMode.system;
      default:       return ThemeMode.dark;
    }
  }

  static String _themeName(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:  return 'light';
      case ThemeMode.system: return 'system';
      default:               return 'dark';
    }
  }
}
