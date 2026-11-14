/// Agreed report categories. Must match the CHECK constraint in migration 0001.
/// To add a category: agree with the team, then add a NEW migration + update here.
enum ReportCategory {
  safetyHazard('safety_hazard', 'Safety Hazard'),
  facilityDamage('facility_damage', 'Facility Damage'),
  suspiciousActivity('suspicious_activity', 'Suspicious Activity'),
  lighting('lighting', 'Lighting'),
  other('other', 'Other');

  const ReportCategory(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ReportCategory fromDb(String value) =>
      ReportCategory.values.firstWhere(
        (c) => c.dbValue == value,
        orElse: () => throw FormatException('Unknown report category: $value'),
      );
}
