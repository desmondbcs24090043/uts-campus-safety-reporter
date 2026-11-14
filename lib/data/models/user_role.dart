/// Role stored in `profiles.role`.
enum UserRole {
  student('student'),
  admin('admin');

  const UserRole(this.dbValue);
  final String dbValue;

  static UserRole fromDb(String value) => UserRole.values.firstWhere(
        (r) => r.dbValue == value,
        orElse: () => throw FormatException('Unknown role: $value'),
      );
}
