// Dashboard V1 widget smoke tests.
// Run from the Flutter project root:
// flutter test test/preview_smoke_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/preview_app.dart';

// Select only the vertical ListView. My Reports also contains a horizontal
// status-filter scroller, so matching all Scrollables is ambiguous.
Finder scrollableInside(String listKey) => find.descendant(
  of: find.byKey(Key(listKey)),
  matching: find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
  ),
);

void main() {
  testWidgets('Dashboard shows summary counts and report entry', (tester) async {
    await tester.pumpWidget(const CampusSafetyPreviewApp());

    expect(find.text('Report an Issue'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);

    // Recent Reports is below the fold in the default test viewport.
    await tester.scrollUntilVisible(
      find.text('Recent Reports'),
      180,
      scrollable: scrollableInside('dashboard-list'),
    );
    expect(find.text('Recent Reports'), findsOneWidget);
  });

  testWidgets('My Reports filter displays pending reports', (tester) async {
    await tester.pumpWidget(const CampusSafetyPreviewApp());

    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-pending')));
    await tester.pumpAndSettle();

    expect(find.text('2 reports'), findsOneWidget);
    expect(find.text('Broken corridor light'), findsOneWidget);

    // A ListView creates only its currently visible children.
    await tester.scrollUntilVisible(
      find.text('Damaged classroom chair'),
      160,
      scrollable: scrollableInside('my-reports-list'),
    );
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

    // Report progress appears lower down the scrollable details screen.
    await tester.scrollUntilVisible(
      find.text('Report progress'),
      160,
      scrollable: scrollableInside('report-details'),
    );
    expect(find.text('Report progress'), findsOneWidget);
  });

  testWidgets('Report an Issue shows the integration placeholder', (tester) async {
    await tester.pumpWidget(const CampusSafetyPreviewApp());

    await tester.tap(find.byKey(const Key('report-issue-cta')));
    await tester.pumpAndSettle();
    expect(
      find.text('Report an Issue is not connected yet'),
      findsOneWidget,
    );
  });
}
