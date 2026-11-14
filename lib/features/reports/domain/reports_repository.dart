import 'report_record.dart';

// The eventual Supabase implementation must scope results to the authenticated
// user using the current auth session and Row Level Security (RLS).
// Do not accept an arbitrary userId from client UI as an authorisation check.
abstract class ReportsRepository {
  Future<List<ReportRecord>> fetchMyReports();
}
