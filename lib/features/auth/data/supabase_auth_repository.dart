import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/user_role.dart';
import '../../../data/repositories/profile_repository.dart';
import 'auth_repository.dart';

/// Real student authentication. The existing mock preview is unchanged.
/// Uses the same Supabase client, profiles table and role rules as Web Admin.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      _profiles = ProfileRepository(client ?? Supabase.instance.client);

  final SupabaseClient _client;
  final ProfileRepository _profiles;

  @override
  Future<void> signUp({required String email, required String password}) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    // Registration should return to the sign-in page regardless of whether
    // email confirmation is enabled in the team's Supabase project.
    if (response.session != null) {
      await _client.auth.signOut();
    }
  }

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.user == null) {
      throw StateError('Unable to sign in. Please try again.');
    }
    try {
      final role = await _profiles.fetchMyRole();
      if (role != UserRole.student) {
        throw StateError('Staff accounts must use the Web Admin portal.');
      }
      return UserRole.student.dbValue;
    } catch (_) {
      // Do not leave an unauthorised role signed into the student interface.
      await _client.auth.signOut();
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
