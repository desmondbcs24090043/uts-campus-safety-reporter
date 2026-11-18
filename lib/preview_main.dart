// Standalone Member 2 preview entry point.
// Run: flutter run -d chrome -t lib/preview_main.dart
// This intentionally does not modify lib/main.dart or Member 1's auth flow.
import 'package:flutter/material.dart';
import 'preview/app_appearance.dart';
import 'preview/preview_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppAppearance.restore();
  runApp(const CampusSafetyPreviewApp());
}
