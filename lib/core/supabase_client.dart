import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // 等 Member 4 给你真实的 URL 和 Key 后，再替换这里
  static const String supabaseUrl = 'https://placeholder.supabase.co';
  static const String supabaseAnonKey = 'placeholder-key';
}

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey, // 修正了警告
  );
}

SupabaseClient get supabase => Supabase.instance.client;