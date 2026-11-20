import 'package:flutter/material.dart';

import '../preview/preview_theme.dart';

/// Staff-facing theme using the Student App's locked colour tokens.
/// This does not change the app's Supabase/auth/reporting logic.
ThemeData buildAdminTheme({bool dark = false}) {
  final base = buildPreviewTheme(dark: dark);
  final border = dark ? const Color(0xFF384D67) : PreviewColours.border;
  final surface = dark ? const Color(0xFF1B2C44) : Colors.white;
  final accent = dark ? const Color(0xFFA6C8FF) : PreviewColours.navy;
  final buttonBg = dark ? const Color(0xFF194478) : PreviewColours.navy;

  return base.copyWith(
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: buttonBg,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: border),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: surface,
      selectedColor: dark ? const Color(0xFF263D5D) : PreviewColours.paleBlue,
      side: BorderSide(color: border),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: accent, fontWeight: FontWeight.w600),
    ),
  );
}
