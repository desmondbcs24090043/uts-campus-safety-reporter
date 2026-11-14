// Member 2 integrated UI smoke tests. Demo data only.
// flutter test test/reports_v2_ui_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview_integrated_main.dart';

void main() {
  testWidgets('V1 design is presented with data from V2 BLoC', (tester) async {
    await tester.pumpWidget(const CampusSafetyIntegratedRoot());
    await tester.pumpAndSettle();
    expect(find.text('Hello, Student 👋'), findsOneWidget);
    expect(find.text('Report an Issue'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('In Progress'), findsWidgets);
  });

  testWidgets('BLoC-backed status filter and search work together', (tester) async {
    await tester.pumpWidget(const CampusSafetyIntegratedRoot());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-pending')));
    await tester.pumpAndSettle();
    expect(find.text('2 reports'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('reports-search')), 'chair');
    await tester.pumpAndSettle();
    expect(find.text('1 reports'), findsOneWidget);
    expect(find.text('Damaged classroom chair'), findsOneWidget);
  });

  testWidgets('Report Details opens from a BLoC-backed record', (tester) async {
    await tester.pumpWidget(const CampusSafetyIntegratedRoot());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-card-CSR-2026-001')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report-details')), findsOneWidget);
    expect(find.text('CSR-2026-001'), findsOneWidget);
  });

  testWidgets('Reload restores all reports after filtering', (tester) async {
    await tester.pumpWidget(const CampusSafetyIntegratedRoot());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-pending')));
    await tester.pumpAndSettle();
    expect(find.text('2 reports'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reload-reports')));
    await tester.pumpAndSettle();
    expect(find.text('6 reports'), findsOneWidget);
  });
}
