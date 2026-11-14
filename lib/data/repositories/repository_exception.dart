import 'package:supabase_flutter/supabase_flutter.dart';

/// One error type for the whole data layer, with a message that is safe to
/// show to the user. BLoCs/pages only need to catch this.
class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  /// Converts Supabase errors into friendly messages.
  factory RepositoryException.from(Object error) {
    if (error is RepositoryException) return error;
    if (error is PostgrestException) {
      switch (error.code) {
        case '42501': // insufficient_privilege / RLS violation
          return RepositoryException(
              'You do not have permission to do this.', cause: error);
        case '23514': // check_violation
          return RepositoryException(
              'Some values are not valid. Please check the form.', cause: error);
        case 'PGRST116': // .single() found 0 rows
          return RepositoryException(
              'Report not found or you are not allowed to access it.',
              cause: error);
      }
      return RepositoryException('Server error: ${error.message}', cause: error);
    }
    if (error is StorageException) {
      return RepositoryException('Photo error: ${error.message}', cause: error);
    }
    if (error is AuthException) {
      return RepositoryException(error.message, cause: error);
    }
    return RepositoryException(
        'Network problem. Please check your connection and try again.',
        cause: error);
  }

  @override
  String toString() => 'RepositoryException: $message';
}
