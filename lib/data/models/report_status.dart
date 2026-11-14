/// The ONLY three report statuses allowed anywhere in the project.
/// Must match the CHECK constraint in migration 0001.
enum ReportStatus {
  pending('pending', 'Pending'),
  inProgress('in_progress', 'In Progress'),
  resolved('resolved', 'Resolved');

  const ReportStatus(this.dbValue, this.label);

  /// Exact string stored in the database / sent over the REST API.
  final String dbValue;

  /// Human-friendly text for the UI.
  final String label;

  static ReportStatus fromDb(String value) => ReportStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => throw FormatException('Unknown report status: $value'),
      );

  /// The next step in the workflow pending -> in_progress -> resolved,
  /// or null when already resolved.
  ReportStatus? get next => switch (this) {
        ReportStatus.pending => ReportStatus.inProgress,
        ReportStatus.inProgress => ReportStatus.resolved,
        ReportStatus.resolved => null,
      };
}
