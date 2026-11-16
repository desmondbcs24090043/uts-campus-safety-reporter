import 'package:flutter/material.dart';

import 'app_appearance.dart';

/// Original light-mode design tokens, retained for compatibility with the
/// feature/domain code and test fixtures. UI widgets use AdaptivePalette.
abstract final class PreviewColours {
  static const navy = Color(0xFF153C79);
  static const deepNavy = Color(0xFF10294E);
  static const blue = Color(0xFF3973D6);
  static const ink = Color(0xFF202C42);
  static const muted = Color(0xFF718099);
  static const background = Color(0xFFF6F8FC);
  static const border = Color(0xFFE5EAF2);
  static const paleBlue = Color(0xFFEDF3FD);
  static const pending = Color(0xFF966318);
  static const pendingBg = Color(0xFFFFF4E0);
  static const progress = Color(0xFF2768B9);
  static const progressBg = Color(0xFFEAF3FF);
  static const resolved = Color(0xFF257E5D);
  static const resolvedBg = Color(0xFFE5F6ED);
}

/// A palette driven by the app-wide appearance notifier. Reading it inside a
/// widget's build provides real dark colours for existing custom decorations.
abstract final class AdaptivePalette {
  static bool get _dark => AppAppearance.isDark;
  static Color get navy =>
      _dark ? const Color(0xFFA6C8FF) : PreviewColours.navy;
  static Color get heroNavy =>
      _dark ? const Color(0xFF194478) : PreviewColours.navy;
  static Color get deepNavy =>
      _dark ? const Color(0xFF162F56) : PreviewColours.deepNavy;
  static Color get blue =>
      _dark ? const Color(0xFF9FC6FF) : PreviewColours.blue;
  static Color get ink => _dark ? const Color(0xFFEAF1FF) : PreviewColours.ink;
  static Color get muted =>
      _dark ? const Color(0xFFB5C4D9) : PreviewColours.muted;
  static Color get background =>
      _dark ? const Color(0xFF111D30) : PreviewColours.background;
  static Color get surface => _dark ? const Color(0xFF1B2C44) : Colors.white;
  static Color get border =>
      _dark ? const Color(0xFF384D67) : PreviewColours.border;
  static Color get paleBlue =>
      _dark ? const Color(0xFF263D5D) : PreviewColours.paleBlue;
  static Color get pending =>
      _dark ? const Color(0xFFF5CC86) : PreviewColours.pending;
  static Color get pendingBg =>
      _dark ? const Color(0xFF5B4529) : PreviewColours.pendingBg;
  static Color get progress =>
      _dark ? const Color(0xFFA9CFFF) : PreviewColours.progress;
  static Color get progressBg =>
      _dark ? const Color(0xFF213B5C) : PreviewColours.progressBg;
  static Color get resolved =>
      _dark ? const Color(0xFF90D8B6) : PreviewColours.resolved;
  static Color get resolvedBg =>
      _dark ? const Color(0xFF1F4039) : PreviewColours.resolvedBg;
  static Color get warningBg =>
      _dark ? const Color(0xFF55432A) : const Color(0xFFFFF9ED);
  static Color get warningBorder =>
      _dark ? const Color(0xFF796243) : const Color(0xFFF0DFBD);
  static Color get warningFg =>
      _dark ? const Color(0xFFF5C477) : const Color(0xFF98661B);
}

ThemeData buildPreviewTheme({bool dark = false}) {
  final ink = dark ? const Color(0xFFEAF1FF) : PreviewColours.ink;
  final muted = dark ? const Color(0xFFB5C4D9) : PreviewColours.muted;
  final bg = dark ? const Color(0xFF111D30) : PreviewColours.background;
  final surface = dark ? const Color(0xFF1B2C44) : Colors.white;
  final border = dark ? const Color(0xFF384D67) : PreviewColours.border;
  final accent = dark ? const Color(0xFFA6C8FF) : PreviewColours.navy;
  final seed = dark ? const Color(0xFF9FC6FF) : PreviewColours.blue;
  final paleBlue = dark ? const Color(0xFF263D5D) : PreviewColours.paleBlue;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: dark ? Brightness.dark : Brightness.light,
    surface: surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    cardColor: surface,
    dividerColor: border,
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 29,
        fontWeight: FontWeight.w800,
        height: 1.12,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: ink),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: bg,
      foregroundColor: ink,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 75,
      backgroundColor: surface,
      indicatorColor: paleBlue,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? accent : muted,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: seed, width: 1.6),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
    dialogTheme: DialogThemeData(backgroundColor: surface),
  );
}
