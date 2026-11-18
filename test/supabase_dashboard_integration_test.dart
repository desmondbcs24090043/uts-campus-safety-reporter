import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:team_repo/data/models/incident_report.dart';
import 'package:team_repo/data/models/report_category.dart';
import 'package:team_repo/data/models/report_status.dart' as db;
import 'package:team_repo/data/repositories/incident_report_repository.dart';

import 'package:team_repo/features/reports/data/supabase_reports_adapter.dart';
import 'package:team_repo/features/reports/presentation/reports_bloc.dart';
import 'package:team_repo/features/reports/presentation/reports_event.dart';
import 'package:team_repo/preview_integrated/preview_app_integrated.dart';

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

List<IncidentReport> sampleReports() {
  final now = DateTime.utc(2026, 11, 15);

  return [
    IncidentReport(
      id: 'test-001',
      reporterId: 'student-001',
      category: ReportCategory.lighting,
      description: 'Broken corridor light',
      latitude: 1.5,
      longitude: 111.0,
      photoPath: null,
      status: db.ReportStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),
    IncidentReport(
      id: 'test-002',
      reporterId: 'student-001',
      category: ReportCategory.safetyHazard,
      description: 'Wet floor near stairs',
      latitude: 1.6,
      longitude: 111.1,
      photoPath: null,
      status: db.ReportStatus.inProgress,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

Widget buildTestApp() {
  final repository = SupabaseReportsAdapter(
    FakeIncidentRepository(sampleReports()),
  );

  return BlocProvider(
    create: (_) => ReportsBloc(repository)
      ..add(const ReportsRequested()),
    child: const CampusSafetyIntegratedPreviewApp(),
  );
}

void main() {
  testWidgets('Supabase reports appear in My Reports', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();

    expect(find.text('2 reports'), findsOneWidget);
    expect(find.text('Lighting'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('report-card-test-001')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('report-details')),
      findsOneWidget,
    );
    expect(find.text('test-001'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final safetyReport = find.text('Safety Hazard');
    await tester.scrollUntilVisible(
      safetyReport,
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('my-reports-list')),
        matching: find.byType(Scrollable),
      ).first,
    );
    expect(safetyReport, findsOneWidget);
  });

  testWidgets('Status filtering and search work', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filter-pending')));
    await tester.pumpAndSettle();

    expect(find.text('1 reports'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('reports-search')),
      'SAFETY',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('empty-reports')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('reports-search')),
      'LIGHTING',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('report-card-test-001')),
      findsOneWidget,
    );
  });
}
