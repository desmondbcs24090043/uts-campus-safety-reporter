import 'package:flutter/material.dart';

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

ThemeData buildPreviewTheme() {
  final colourScheme = ColorScheme.fromSeed(
    seedColor: PreviewColours.blue,
    brightness: Brightness.light,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colourScheme,
    scaffoldBackgroundColor: PreviewColours.background,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 29, fontWeight: FontWeight.w800, height: 1.12, color: PreviewColours.ink),
      headlineSmall: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: PreviewColours.ink),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PreviewColours.ink),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PreviewColours.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: PreviewColours.ink),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: PreviewColours.background,
      foregroundColor: PreviewColours.ink,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 75,
      backgroundColor: Colors.white,
      indicatorColor: PreviewColours.paleBlue,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        color: states.contains(WidgetState.selected) ? PreviewColours.navy : PreviewColours.muted,
      )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: PreviewColours.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: PreviewColours.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: PreviewColours.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: PreviewColours.blue, width: 1.6)),
    ),
  );
}
