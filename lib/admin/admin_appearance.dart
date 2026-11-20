import 'package:flutter/material.dart';

/// In-memory preferences for the staff workspace only.
/// These do not change Student App theme settings or Supabase data.
class AdminAppearance extends ChangeNotifier {
  AdminAppearance._();

  static final AdminAppearance instance = AdminAppearance._();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
  }
}
