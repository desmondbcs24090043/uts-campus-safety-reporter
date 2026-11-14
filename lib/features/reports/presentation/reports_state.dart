import '../domain/report_record.dart';

sealed class ReportsState {
  const ReportsState();
}

final class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

final class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

final class ReportsLoaded extends ReportsState {
  ReportsLoaded({
    required List<ReportRecord> records,
    this.statusFilter,
    this.query = '',
  }) : records = List<ReportRecord>.unmodifiable(records);

  final List<ReportRecord> records;
  final ReportStatus? statusFilter;
  final String query;

  List<ReportRecord> get visibleRecords {
    final term = query.trim().toLowerCase();
    return records.where((record) {
      final matchesStatus = statusFilter == null || record.status == statusFilter;
      final haystack = '${record.id} ${record.title} ${record.category} ${record.location}'.toLowerCase();
      return matchesStatus && (term.isEmpty || haystack.contains(term));
    }).toList(growable: false);
  }

  bool get hasNoReports => records.isEmpty;
  bool get hasNoMatchingReports => records.isNotEmpty && visibleRecords.isEmpty;

  ReportsLoaded copyWithQuery(String nextQuery) => ReportsLoaded(
        records: records,
        statusFilter: statusFilter,
        query: nextQuery,
      );

  ReportsLoaded copyWithStatus(ReportStatus? nextStatus) => ReportsLoaded(
        records: records,
        statusFilter: nextStatus,
        query: query,
      );
}

final class ReportsFailure extends ReportsState {
  const ReportsFailure(this.message);
  final String message;
}
