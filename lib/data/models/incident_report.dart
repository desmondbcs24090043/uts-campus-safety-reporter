import 'report_category.dart';
import 'report_status.dart';

/// One row of `public.incident_reports`.
///
/// This class IS the shared data contract. Member 2 (Dashboard), Member 3
/// (Submit Incident) and Member 5 (offline cache) should all use it instead
/// of reading raw maps.
class IncidentReport {
  const IncidentReport({
    required this.id,
    required this.reporterId,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.photoPath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String reporterId;
  final ReportCategory category;
  final String description;
  final double latitude;
  final double longitude;

  /// Path inside the private `report-photos` bucket (NOT a URL).
  /// Use `IncidentReportRepository.photoUrl()` to get a viewable link.
  final String? photoPath;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Columns to request from the REST API (keeps responses small and explicit).
  static const String selectColumns =
      'id, reporter_id, category, description, latitude, longitude, '
      'photo_path, status, created_at, updated_at';

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      category: ReportCategory.fromDb(json['category'] as String),
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photoPath: json['photo_path'] as String?,
      status: ReportStatus.fromDb(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Full representation, e.g. for caching in SQLite (Member 5).
  Map<String, dynamic> toJson() => {
        'id': id,
        'reporter_id': reporterId,
        'category': category.dbValue,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'photo_path': photoPath,
        'status': status.dbValue,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  IncidentReport copyWith({ReportStatus? status, DateTime? updatedAt}) {
    return IncidentReport(
      id: id,
      reporterId: reporterId,
      category: category,
      description: description,
      latitude: latitude,
      longitude: longitude,
      photoPath: photoPath,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Data a student sends when creating a report.
/// Only these columns are allowed by the database (see migration 0002).
class NewIncidentReport {
  const NewIncidentReport({
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.photoPath,
  });

  final ReportCategory category;
  final String description;
  final double latitude;
  final double longitude;
  final String? photoPath;

  /// Validation that mirrors the database CHECK constraints, so the form can
  /// show a friendly message before calling the API. Returns null if valid.
  String? validate() {
    final text = description.trim();
    if (text.length < 5) return 'Description must be at least 5 characters.';
    if (text.length > 1000) return 'Description must be at most 1000 characters.';
    if (latitude < -90 || latitude > 90) return 'Invalid latitude.';
    if (longitude < -180 || longitude > 180) return 'Invalid longitude.';
    return null;
  }

  /// Body for `POST /rest/v1/incident_reports`.
  /// reporter_id and status are NOT sent: the database fills them in.
  Map<String, dynamic> toInsertJson() => {
        'category': category.dbValue,
        'description': description.trim(),
        'latitude': latitude,
        'longitude': longitude,
        if (photoPath != null) 'photo_path': photoPath,
      };
}
