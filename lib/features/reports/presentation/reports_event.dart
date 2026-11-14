import '../domain/report_record.dart';

sealed class ReportsEvent {
  const ReportsEvent();
}

// Can be used for initial loading and explicit refresh.
final class ReportsRequested extends ReportsEvent {
  const ReportsRequested();
}

final class ReportsStatusFilterChanged extends ReportsEvent {
  const ReportsStatusFilterChanged(this.status);
  final ReportStatus? status; // null means All.
}

final class ReportsSearchChanged extends ReportsEvent {
  const ReportsSearchChanged(this.query);
  final String query;
}
