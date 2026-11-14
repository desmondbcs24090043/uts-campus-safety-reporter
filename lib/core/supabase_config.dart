import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase connection settings.
///
/// Values come from `--dart-define-from-file=env.json` at build/run time,
/// so NO keys are written in the source code or committed to GitHub.
/// Only the *publishable* (anon) key belongs in the app. The service_role /
/// secret key must NEVER be used in Flutter code.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Name of the private Storage bucket that holds report photos.
  static const String photoBucket = 'report-photos';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  /// Call once in `main()` before `runApp`.
  static Future<void> initialize() async {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Run with '
        '--dart-define-from-file=env.json (see env.example.json).',
      );
    }
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
