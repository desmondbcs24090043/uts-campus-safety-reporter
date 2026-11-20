import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:team_repo/data/models/incident_report.dart';
import 'package:team_repo/data/models/report_category.dart';
import 'package:team_repo/data/models/report_status.dart' as db;
import 'package:team_repo/data/repositories/incident_report_repository.dart';
import 'package:team_repo/data/repositories/repository_exception.dart';
import 'package:team_repo/features/reports/data/demo_reports_repository.dart';
import 'package:team_repo/features/reports/presentation/report_details_loader.dart';
import 'package:team_repo/features/reports/presentation/reports_bloc.dart';
import 'package:team_repo/features/reports/presentation/reports_event.dart';
import 'package:team_repo/preview/preview_theme.dart';
import 'package:team_repo/preview_integrated/preview_app_integrated.dart';

IncidentReport savedReport({
  String id = 'report-1',
  String owner = 'student-a',
  String description = 'Fresh report from the repository',
  String? photoPath,
  db.ReportStatus status = db.ReportStatus.pending,
}) => IncidentReport(
  id: id,
  reporterId: owner,
  category: ReportCategory.lighting,
  description: description,
  latitude: 1.5,
  longitude: 111,
  photoPath: photoPath,
  status: status,
  createdAt: DateTime.utc(2026, 11, 19),
  updatedAt: DateTime.utc(2026, 11, 20),
);

class DetailsRepositoryFake implements IncidentReportRepository {
  DetailsRepositoryFake(this.read);

  Future<IncidentReport> Function(String id) read;
  final calls = <String>[];
  int photoUrlCalls = 0;

  @override
  Future<IncidentReport> fetchReport(String id) {
    calls.add(id);
    return read(id);
  }

  @override
  Future<String?> photoUrl(
    String? photoPath, {
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    photoUrlCalls++;
    throw StateError('Private photo integration is deliberately deferred');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected repository operation: ${invocation.memberName}',
  );
}

RepositoryException denied(String code) => RepositoryException.from(
  PostgrestException(message: 'Server-only diagnostic', code: code),
);

void main() {
  late String? userId;
  late StreamController<String?> identities;

  setUp(() {
    userId = 'student-a';
    identities = StreamController<String?>.broadcast(sync: true);
  });
  tearDown(() async {
    await identities.close();
  });

  ReportDetailsLoader loaderFor(DetailsRepositoryFake repository) {
    final loader = ReportDetailsLoader(
      reportId: 'report-1',
      repository: repository,
      currentUserId: () => userId,
      identityChanges: identities.stream,
    );
    addTearDown(loader.dispose);
    return loader;
  }

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> reveal(WidgetTester tester, String list, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      140,
      scrollable: find
          .descendant(
            of: find.byKey(Key(list)),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget);
  }

  Widget page(DetailsRepositoryFake repository) => MaterialApp(
    theme: buildPreviewTheme(),
    home: LiveStudentReportDetailsPage(
      reportId: 'report-1',
      repository: repository,
      currentUserId: () => userId,
      identityChanges: identities.stream,
    ),
  );

  test(
    'starts loading and returns the latest complete shared record',
    () async {
      final response = Completer<IncidentReport>();
      final repository = DetailsRepositoryFake((_) => response.future);
      final loader = loaderFor(repository);
      expect(loader.state.status, ReportDetailsStatus.loading);
      expect(loader.state.report, isNull);
      final report = savedReport(status: db.ReportStatus.inProgress);
      response.complete(report);
      await flush();
      expect(loader.state.status, ReportDetailsStatus.loaded);
      expect(loader.state.report, same(report));
      expect(repository.calls, ['report-1']);
    },
  );

  for (final (code, status) in [
    ('PGRST116', ReportDetailsStatus.notFound),
    ('42501', ReportDetailsStatus.permissionDenied),
  ]) {
    test('classifies $code without retaining report content', () async {
      final loader = loaderFor(
        DetailsRepositoryFake((_) async => throw denied(code)),
      );
      await flush();
      expect(loader.state.status, status);
      expect(loader.state.report, isNull);
      expect(loader.canRetry, isTrue);
    });
  }

  test(
    'repository/network error is retryable and Retry loads fresh data',
    () async {
      final repository = DetailsRepositoryFake(
        (_) async => throw const RepositoryException('Network problem'),
      );
      final loader = loaderFor(repository);
      await flush();
      expect(loader.state.status, ReportDetailsStatus.failure);
      repository.read = (_) async => savedReport();
      await loader.load();
      expect(loader.state.status, ReportDetailsStatus.loaded);
      expect(repository.calls, ['report-1', 'report-1']);
    },
  );

  test('an older success cannot overwrite a newer response', () async {
    final first = Completer<IncidentReport>();
    final second = Completer<IncidentReport>();
    var requests = 0;
    final repository = DetailsRepositoryFake(
      (_) => requests++ == 0 ? first.future : second.future,
    );
    final loader = loaderFor(repository);
    final reload = loader.load();
    second.complete(savedReport(status: db.ReportStatus.resolved));
    await reload;
    first.complete(savedReport(status: db.ReportStatus.pending));
    await flush();
    expect(loader.state.report!.status, db.ReportStatus.resolved);
  });

  test('an older error cannot overwrite a newer success', () async {
    final first = Completer<IncidentReport>();
    var requests = 0;
    final loader = loaderFor(
      DetailsRepositoryFake(
        (_) => requests++ == 0 ? first.future : Future.value(savedReport()),
      ),
    );
    await loader.load();
    first.completeError(denied('42501'));
    await flush();
    expect(loader.state.status, ReportDetailsStatus.loaded);
  });

  test(
    'identity change clears loaded data and never revives the old route',
    () async {
      final repository = DetailsRepositoryFake((_) async => savedReport());
      final loader = loaderFor(repository);
      await flush();
      userId = 'student-b';
      identities.add(userId);
      expect(loader.state.status, ReportDetailsStatus.identityChanged);
      expect(loader.state.report, isNull);
      expect(loader.canRetry, isFalse);
      userId = 'student-a';
      identities.add(userId);
      await loader.load();
      expect(repository.calls.length, 1);
      expect(loader.state.report, isNull);
    },
  );

  test('identity change rejects an in-flight response', () async {
    final response = Completer<IncidentReport>();
    final loader = loaderFor(DetailsRepositoryFake((_) => response.future));
    userId = 'student-b';
    identities.add(userId);
    response.complete(savedReport());
    await flush();
    expect(loader.state.status, ReportDetailsStatus.identityChanged);
    expect(loader.state.report, isNull);
  });

  test(
    'completion checks identity even before an event is delivered',
    () async {
      final response = Completer<IncidentReport>();
      final loader = loaderFor(DetailsRepositoryFake((_) => response.future));
      userId = null;
      response.complete(savedReport());
      await flush();
      expect(loader.state.status, ReportDetailsStatus.identityChanged);
      expect(loader.state.report, isNull);
    },
  );

  test('no authenticated user produces no repository request', () async {
    userId = null;
    final repository = DetailsRepositoryFake((_) async => savedReport());
    final loader = loaderFor(repository);
    expect(loader.state.status, ReportDetailsStatus.identityChanged);
    expect(repository.calls, isEmpty);
  });

  test(
    'foreign owner data is discarded even if a repository returns it',
    () async {
      final loader = loaderFor(
        DetailsRepositoryFake((_) async => savedReport(owner: 'student-b')),
      );
      await flush();
      expect(loader.state.status, ReportDetailsStatus.permissionDenied);
      expect(loader.state.report, isNull);
    },
  );

  test('a mismatched report ID is discarded', () async {
    final loader = loaderFor(
      DetailsRepositoryFake((_) async => savedReport(id: 'other-report')),
    );
    await flush();
    expect(loader.state.status, ReportDetailsStatus.permissionDenied);
    expect(loader.state.report, isNull);
  });

  test('same-user token refresh preserves current data', () async {
    final loader = loaderFor(DetailsRepositoryFake((_) async => savedReport()));
    await flush();
    identities.add('student-a');
    expect(loader.state.status, ReportDetailsStatus.loaded);
  });

  testWidgets(
    'loading shows progress and success preserves the existing cards',
    (tester) async {
      phone(tester);
      final response = Completer<IncidentReport>();
      await tester.pumpWidget(
        page(DetailsRepositoryFake((_) => response.future)),
      );
      expect(find.text('Loading report'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      response.complete(savedReport());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('report-details')), findsOneWidget);
      expect(find.text('Fresh report from the repository'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Attached Photos'), findsOneWidget);
      await reveal(tester, 'report-details', find.text('No photo attached'));
      expect(find.text('No photo attached'), findsOneWidget);
      await reveal(tester, 'report-details', find.text('Report progress'));
      expect(find.text('Report progress'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final code in ['PGRST116', '42501']) {
    testWidgets('$code shows a private unavailable state and Retry', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        page(DetailsRepositoryFake((_) async => throw denied(code))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Report unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('Server-only diagnostic'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('failure Retry returns to loading then success', (tester) async {
    phone(tester);
    final repository = DetailsRepositoryFake(
      (_) async => throw StateError('Private diagnostic'),
    );
    await tester.pumpWidget(page(repository));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load report'), findsOneWidget);
    expect(find.textContaining('Private diagnostic'), findsNothing);
    final next = Completer<IncidentReport>();
    repository.read = (_) => next.future;
    await tester.tap(find.byKey(const Key('report-details-retry')));
    await tester.pump();
    expect(find.text('Loading report'), findsOneWidget);
    next.complete(savedReport());
    await tester.pumpAndSettle();
    expect(find.text('Fresh report from the repository'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'private attachment uses a safe placeholder without signing or public URL',
    (tester) async {
      phone(tester);
      final repository = DetailsRepositoryFake(
        (_) async => savedReport(photoPath: 'student-a/private.jpg'),
      );
      await tester.pumpWidget(page(repository));
      await tester.pumpAndSettle();
      expect(find.text('Photo preview unavailable'), findsOneWidget);
      expect(find.text('No photo attached'), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(repository.photoUrlCalls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('identity change removes private content immediately', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      page(DetailsRepositoryFake((_) async => savedReport())),
    );
    await tester.pumpAndSettle();
    userId = 'student-b';
    identities.add(userId);
    await tester.pumpAndSettle();
    expect(find.text('Session changed'), findsOneWidget);
    expect(find.text('Fresh report from the repository'), findsNothing);
    expect(find.byKey(const Key('report-details-retry')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a response after page disposal cannot restore data', (
    tester,
  ) async {
    phone(tester);
    final response = Completer<IncidentReport>();
    await tester.pumpWidget(
      page(DetailsRepositoryFake((_) => response.future)),
    );
    await tester.pumpWidget(const SizedBox());
    response.complete(savedReport());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Fresh report from the repository'), findsNothing);
  });

  testWidgets(
    'normal navigation reloads latest status each time Details reopens',
    (tester) async {
      phone(tester);
      var status = db.ReportStatus.pending;
      final repository = DetailsRepositoryFake(
        (id) async => savedReport(id: id, status: status),
      );
      final reports = ReportsBloc(DemoReportsRepository())
        ..add(const ReportsRequested());
      addTearDown(reports.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: reports,
          child: CampusSafetyIntegratedPreviewApp(
            reportDetailsBuilder: (id) => LiveStudentReportDetailsPage(
              reportId: id,
              repository: repository,
              currentUserId: () => userId,
              identityChanges: identities.stream,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const Key('report-card-CSR-2026-001'));
      await reveal(tester, 'dashboard-list', card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      final badge = find.byKey(const Key('report-details-status'));
      expect(
        find.descendant(of: badge, matching: find.text('Pending')),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      status = db.ReportStatus.resolved;
      await reveal(tester, 'dashboard-list', card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: badge, matching: find.text('Resolved')),
        findsOneWidget,
      );
      expect(repository.calls, ['CSR-2026-001', 'CSR-2026-001']);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Campus demo Details bypasses the injected live route', (
    tester,
  ) async {
    phone(tester);
    final reports = ReportsBloc(DemoReportsRepository())
      ..add(const ReportsRequested());
    addTearDown(reports.close);
    var liveCalls = 0;
    await tester.pumpWidget(
      BlocProvider.value(
        value: reports,
        child: CampusSafetyIntegratedPreviewApp(
          reportDetailsBuilder: (_) {
            liveCalls++;
            throw StateError('Fixture reached live route');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-campus')));
    await tester.pumpAndSettle();
    final details = find.byKey(const Key('feed-details-CSR-2026-001'));
    await reveal(tester, 'campus-feed-scroll', details);
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(find.text('Report Details'), findsOneWidget);
    expect(liveCalls, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
