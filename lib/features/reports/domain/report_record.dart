// Member 2: API-neutral report model. This is not the Supabase schema.
enum ReportStatus { pending, inProgress, resolved }

extension ReportStatusLabel on ReportStatus {
  String get label => switch (this) {
        ReportStatus.pending => 'Pending',
        ReportStatus.inProgress => 'In Progress',
        ReportStatus.resolved => 'Resolved',
      };

  // Values proposed for discussion with Member 4, not a confirmed DB mapping.
  String get proposedApiValue => switch (this) {
        ReportStatus.pending => 'pending',
        ReportStatus.inProgress => 'in_progress',
        ReportStatus.resolved => 'resolved',
      };
}

class ReportRecord {
  const ReportRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final String location;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
}
