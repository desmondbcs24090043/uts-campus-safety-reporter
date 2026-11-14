import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/data/models/incident_report.dart';
import 'package:team_repo/data/models/report_category.dart';
import 'package:team_repo/data/models/report_status.dart' as db;
import 'package:team_repo/data/repositories/incident_report_repository.dart';
import 'package:team_repo/features/reports/data/supabase_reports_adapter.dart';
import 'package:team_repo/features/reports/domain/report_record.dart' as ui;

class FakeIncidentRepository implements IncidentReportRepository {
  FakeIncidentRepository(this.reports);

  final List<IncidentReport> reports;

  @override
  Future<List<IncidentReport>> fetchMyReports({int limit = 50}) async {
    return reports.take(limit).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  test('Converts Member 4 report into Dashboard format', () async {
    final now = DateTime.utc(2026, 11, 15);

    final report = IncidentReport(
      id: 'test-001',
      reporterId: 'student-001',
      category: ReportCategory.lighting,
      description: 'Broken corridor light',
      latitude: 1.5,
      longitude: 111.0,
      photoPath: null,
      status: db.ReportStatus.inProgress,
      createdAt: now,
      updatedAt: now,
    );

    final adapter = SupabaseReportsAdapter(
      FakeIncidentRepository([report]),
    );

    final records = await adapter.fetchMyReports();

    expect(records.length, 1);
    expect(records.first.title, 'Lighting');
    expect(records.first.location, '1.50000, 111.00000');
    expect(records.first.description, 'Broken corridor light');
    expect(records.first.status, ui.ReportStatus.inProgress);
  });

  test('Returns empty Dashboard when no reports exist', () async {
    final adapter = SupabaseReportsAdapter(
      FakeIncidentRepository([]),
    );

    final records = await adapter.fetchMyReports();

    expect(records, isEmpty);
  });
}