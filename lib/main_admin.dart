// Entry point for the WEB ADMIN (Member 4).
//
// Run in Chrome:
//   flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env.json
// Build for hosting:
//   flutter build web -t lib/main_admin.dart --dart-define-from-file=env.json
//
// The student Android app keeps using lib/main.dart, so the two apps share
// the same models/repositories without touching each other's code.
import 'package:flutter/material.dart';

import 'admin/admin_app.dart';
import 'core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }
  await SupabaseConfig.initialize();
  runApp(const AdminApp());
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase is not configured.\n\n'
              'Copy env.example.json to env.json, fill in your project URL and '
              'publishable key, then run with --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
