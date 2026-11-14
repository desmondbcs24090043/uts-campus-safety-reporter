import '../../../data/repositories/incident_report_repository.dart';
import '../../../data/models/report_status.dart' as db;
import '../domain/report_record.dart' as ui;
import '../domain/reports_repository.dart';

class SupabaseReportsAdapter implements ReportsRepository {
  SupabaseReportsAdapter(this._repository);

  final IncidentReportRepository _repository;

  @override
  Future<List<ui.ReportRecord>> fetchMyReports() async {
    final reports = await _repository.fetchMyReports();

    return reports.map((report) {
      return ui.ReportRecord(
        id: report.id,
        title: report.category.label,
        category: report.category.label,
        location:
            '${report.latitude.toStringAsFixed(5)}, '
            '${report.longitude.toStringAsFixed(5)}',
        description: report.description,
        status: switch (report.status) {
          db.ReportStatus.pending => ui.ReportStatus.pending,
          db.ReportStatus.inProgress => ui.ReportStatus.inProgress,
          db.ReportStatus.resolved => ui.ReportStatus.resolved,
        },
        createdAt: report.createdAt,
      );
    }).toList(growable: false);
  }
}