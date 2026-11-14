// Copy to the team's test/ folder alongside the preview files.
// Run: flutter test test/preview_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/preview_app.dart';

void main() {
  testWidgets('Dashboard shows summary counts and report entry', (tester) async {
    await tester.pumpWidget(const CampusSafetyPreviewApp());
    expect(find.text('Report an Issue'), findsOneWidget);
    expect(find.text('Recent Reports'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
  });

  testWidgets('My Reports filter displays pending reports', (tester) async {
    await tester.pumpWidget(const CampusSafetyPreviewApp());
    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-pending')));
    await tester.pumpAndSettle();
    expect(find.text('2 reports'), findsOneWidget);
    expect(find.text('Broken corridor light'), findsOneWidget);
    expect(find.text('Damaged classroom chair'), findsOneWidget);
  });

  testWidgets('A report opens its detail screen', (tester) async {
    await tester.pumpWidget(const CampusSafetyPreviewApp());
    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-card-CSR-2026-001')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report-details')), findsOneWidget);
    expect(find.text('CSR-2026-001'), findsOneWidget);
    expect(find.text('Report progress'), findsOneWidget);
  });

  testWidgets('Report an Issue is a clearly disabled integration placeholder', (tester) async {
    await tester.pumpWidget(const CampusSafetyPreviewApp());
    await tester.tap(find.byKey(const Key('report-issue-cta')));
    await tester.pumpAndSettle();
    expect(find.text('Report an Issue is not connected yet'), findsOneWidget);
  });
}
