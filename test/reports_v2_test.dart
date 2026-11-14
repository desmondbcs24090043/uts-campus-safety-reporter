import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/features/reports/data/demo_reports_repository.dart';
import 'package:team_repo/features/reports/domain/report_record.dart';
import 'package:team_repo/features/reports/domain/reports_repository.dart';
import 'package:team_repo/features/reports/presentation/reports_bloc.dart';
import 'package:team_repo/features/reports/presentation/reports_event.dart';
import 'package:team_repo/features/reports/presentation/reports_state.dart';

class _FailingReportsRepository implements ReportsRepository {
  @override
  Future<List<ReportRecord>> fetchMyReports() async {
    throw StateError('Simulated internal error');
  }
}

void main() {
  test('Loads all six demonstration reports', () async {
    final bloc = ReportsBloc(DemoReportsRepository());
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere((state) => state is ReportsLoaded);
    bloc.add(const ReportsRequested());
    final state = (await loaded) as ReportsLoaded;
    expect(state.records.length, 6);
    expect(state.visibleRecords.length, 6);
    expect(state.records.where((r) => r.status == ReportStatus.pending).length, 2);
  });

  test('Filters by status and case-insensitive search', () async {
    final bloc = ReportsBloc(DemoReportsRepository());
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere((state) => state is ReportsLoaded);
    bloc.add(const ReportsRequested());
    await loaded;

    final filtered = bloc.stream.firstWhere((state) =>
        state is ReportsLoaded && state.statusFilter == ReportStatus.pending);
    bloc.add(const ReportsStatusFilterChanged(ReportStatus.pending));
    final filteredState = (await filtered) as ReportsLoaded;
    expect(filteredState.visibleRecords.length, 2);

    final searched = bloc.stream.firstWhere((state) =>
        state is ReportsLoaded && state.query == 'CORRIDOR');
    bloc.add(const ReportsSearchChanged('CORRIDOR'));
    final searchedState = (await searched) as ReportsLoaded;
    expect(searchedState.visibleRecords.length, 1);
    expect(searchedState.visibleRecords.single.id, 'CSR-2026-001');
  });

  test('Empty repository returns a loaded empty state', () async {
    final bloc = ReportsBloc(DemoReportsRepository(seed: []));
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere((state) => state is ReportsLoaded);
    bloc.add(const ReportsRequested());
    final state = (await loaded) as ReportsLoaded;
    expect(state.hasNoReports, isTrue);
    expect(state.visibleRecords, isEmpty);
  });

  test('Repository failure returns a safe UI error', () async {
    final bloc = ReportsBloc(_FailingReportsRepository());
    addTearDown(bloc.close);
    final failed = bloc.stream.firstWhere((state) => state is ReportsFailure);
    bloc.add(const ReportsRequested());
    final state = (await failed) as ReportsFailure;
    expect(state.message, contains('Unable to load reports'));
    expect(state.message, isNot(contains('Simulated internal error')));
  });
}
