import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/incident_report.dart';
import '../models/report_status.dart';
import 'repository_exception.dart';

/// The agreed Supabase-backed repository for incident reports.
///
/// Every method maps to ONE Supabase Data REST API call (see
/// docs/backend/API_CONTRACT.md). Security is enforced by RLS in the
/// database, so the same methods are safe for both students and admins:
/// a student calling [fetchReports] simply receives only their own rows.
class IncidentReportRepository {
  IncidentReportRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'incident_reports';

  // ------------------------------------------------------------------
  // READ
  // ------------------------------------------------------------------

  /// Newest first. Student -> own reports only. Admin -> all reports.
  /// [status] filters by one status (Web Admin filter chips).
  /// [limit]/[offset] give simple paging.
  Future<List<IncidentReport>> fetchReports({
    ReportStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query =
          _client.from(_table).select(IncidentReport.selectColumns);
      if (status != null) {
        query = query.eq('status', status.dbValue);
      }
      final rows = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map(IncidentReport.fromJson).toList();
    } catch (e) {
      throw RepositoryException.from(e);
    }
  }

  /// Only the current user's own reports (Student "My Reports" screen).
  /// Admins also use [fetchReports]; this explicit filter makes the
  /// student screen correct even if the user happens to be an admin.
  Future<List<IncidentReport>> fetchMyReports({int limit = 50}) async {
    final uid = _requireUserId();
    try {
      final rows = await _client
          .from(_table)
          .select(IncidentReport.selectColumns)
          .eq('reporter_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(IncidentReport.fromJson).toList();
    } catch (e) {
      throw RepositoryException.from(e);
    }
  }

  /// One report by id (Report Details screen).
  Future<IncidentReport> fetchReport(String id) async {
    try {
      final row = await _client
          .from(_table)
          .select(IncidentReport.selectColumns)
          .eq('id', id)
          .single();
      return IncidentReport.fromJson(row);
    } catch (e) {
      throw RepositoryException.from(e);
    }
  }

  /// Counts per status for dashboard cards, e.g. {pending: 3, ...}.
  Future<Map<ReportStatus, int>> countByStatus() async {
    try {
      final rows = await _client.from(_table).select('status');
      final counts = {for (final s in ReportStatus.values) s: 0};
      for (final row in rows) {
        final s = ReportStatus.fromDb(row['status'] as String);
        counts[s] = counts[s]! + 1;
      }
      return counts;
    } catch (e) {
      throw RepositoryException.from(e);
    }
  }

  // ------------------------------------------------------------------
  // CREATE (student)
  // ------------------------------------------------------------------

  /// Uploads a photo into the private bucket under `<user-id>/...` and
  /// returns the storage path to put in [NewIncidentReport.photoPath].
  Future<String> uploadPhoto(Uint8List bytes, {String extension = 'jpg'}) async {
    final uid = _requireUserId();
    final ext = extension.toLowerCase().replaceAll('.', '');
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => throw const RepositoryException(
          'Only JPG, PNG or WEBP photos are allowed.'),
    };
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw const RepositoryException('Photo must be smaller than 5 MB.');
    }
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}.$ext';
    final path = '$uid/$fileName';
    try {
      await _client.storage.from(SupabaseConfig.photoBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      return path;
    } catch (e) {
      throw RepositoryException.from(e);
    }
  }

  /// Creates a report. The database sets reporter_id = current user and
  /// status = 'pending'. Returns the saved row.
  Future<IncidentReport> createReport(NewIncidentReport report) async {
    final problem = report.validate();
    if (problem != null) throw RepositoryException(problem);
    _requireUserId();
    try {
      final row = await _client
          .from(_table)
          .insert(report.toInsertJson())
          .select(IncidentReport.selectColumns)
          .single();
      return IncidentReport.fromJson(row);
    } catch (e) {
      throw RepositoryException.from(e);
    }
  }

  // ------------------------------------------------------------------
  // UPDATE (admin only - enforced by RLS)
  // ------------------------------------------------------------------

  /// Changes the status of a report. Only admins succeed; for anyone else
  /// the database changes 0 rows and this throws a [RepositoryException].
  Future<IncidentReport> updateStatus(
      String reportId, ReportStatus newStatus) async {
    try {
      final row = await _client
          .from(_table)
          .update({'status': newStatus.dbValue})
          .eq('id', reportId)
          .select(IncidentReport.selectColumns)
          .maybeSingle();
      if (row == null) {
        throw const RepositoryException(
            'You are not allowed to change this report status.');
      }
      return IncidentReport.fromJson(row);
    } catch (e) {
      throw RepositoryException.from(e);
    }
  }

  // ------------------------------------------------------------------
  // PHOTO VIEWING
  // ------------------------------------------------------------------

  /// Short-lived signed URL for a private photo (default 1 hour).
  /// Returns null if the report has no photo.
  Future<String?> photoUrl(String? photoPath,
      {Duration expiresIn = const Duration(hours: 1)}) async {
    if (photoPath == null || photoPath.isEmpty) return null;
    try {
      return await _client.storage
          .from(SupabaseConfig.photoBucket)
          .createSignedUrl(photoPath, expiresIn.inSeconds);
    } catch (e) {
      throw RepositoryException.from(e);
    }
  }

  String _requireUserId() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const RepositoryException('Please log in first.');
    }
    return uid;
  }
}
