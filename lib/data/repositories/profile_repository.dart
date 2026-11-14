import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';
import 'repository_exception.dart';

/// Reads the logged-in user's role from `public.profiles`.
/// Member 1 uses this for student/admin role-based navigation.
class ProfileRepository {
  ProfileRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns the current user's role, or null when nobody is logged in.
  Future<UserRole?> fetchMyRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      // A brand-new user without a profile row is treated as a student.
      if (row == null) return UserRole.student;
      return UserRole.fromDb(row['role'] as String);
    } catch (e) {
      throw RepositoryException.from(e);
    }
  }
}
