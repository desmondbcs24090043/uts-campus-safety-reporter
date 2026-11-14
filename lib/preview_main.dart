// Standalone Member 2 preview entry point.
// Run: flutter run -d chrome -t lib/preview_main.dart
// This intentionally does not modify lib/main.dart or Member 1's auth flow.
import 'package:flutter/material.dart';
import 'preview/preview_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampusSafetyPreviewApp());
}
