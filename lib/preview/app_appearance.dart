import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preview-only presentation preference shared by all student screens.
/// This does not change Android permissions or the notification preference.
abstract final class AppAppearance {
  static const _darkModeKey = 'student.dark_mode';
  static SharedPreferences? _preferences;
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);

  static bool get isDark => darkMode.value;

  static Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    darkMode.value = preferences.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkMode(bool enabled) async {
    darkMode.value = enabled;
    final preferences = _preferences;
    if (preferences != null &&
        !await preferences.setBool(_darkModeKey, enabled)) {
      throw StateError('Could not save the Dark Mode preference.');
    }
  }
}
