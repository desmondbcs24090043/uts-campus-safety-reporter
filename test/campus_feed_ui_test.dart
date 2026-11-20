import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/campus_feed_ui.dart';

void main() {
  testWidgets('Campus feed identifies all records as preview data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampusFeedPreviewPage())),
    );
    expect(find.text('Campus reports'), findsOneWidget);
    expect(find.textContaining('Fictional sample reports'), findsOneWidget);
    expect(find.byKey(const Key('feed-filter-all')), findsOneWidget);
  });

  testWidgets('Campus feed category filter changes visible count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampusFeedPreviewPage())),
    );
    await tester.tap(find.byKey(const Key('feed-filter-safety')));
    await tester.pumpAndSettle();
    expect(find.text('2 shown'), findsOneWidget);
  });

  testWidgets('Comments show fictional author, time, staff and local posting', (
    tester,
  ) async {
    // Use a realistic phone-sized viewport: the previous test scrolled the
    // bottom sheet by a hard-coded distance in the 800x600 test viewport,
    // making the author/post/delete checks sensitive to layout height.
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampusFeedPreviewPage())),
    );
    final open = find.byKey(const Key('comments-CSR-2026-001'));
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    await tester.tap(open);
    await tester.pumpAndSettle();

    expect(find.text('Alex T. (sample)'), findsOneWidget);
    expect(find.text('Campus Safety Team (sample)'), findsOneWidget);
    expect(find.byKey(const Key('feed-staff-badge')), findsOneWidget);
    expect(find.textContaining('19 Nov 2026'), findsWidgets);
    expect(find.textContaining('fictional or local'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('feed-comment-input')),
      'This is a local test comment',
    );
    await tester.tap(find.byKey(const Key('feed-comment-send')));
    await tester.pumpAndSettle();

    expect(find.text('You (demo)'), findsOneWidget);
    expect(find.text('This is a local test comment'), findsOneWidget);
    final delete = find.byKey(const Key('feed-delete-own-comment'));
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('This is a local test comment'), findsNothing);
  });

  testWidgets(
    'Helpful on a sample comment toggles and persists while feed stays open',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CampusFeedPreviewPage())),
      );
      final open = find.byKey(const Key('comments-CSR-2026-001'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();

      final helpful = find.byKey(const Key('feed-helpful-sample-student-1'));
      expect(helpful, findsOneWidget);
      expect(
        find.descendant(of: helpful, matching: find.text('Helpful')),
        findsOneWidget,
      );
      await tester.tap(helpful);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: helpful, matching: find.text('Helpful · 1')),
        findsOneWidget,
      );
      await tester.tap(helpful);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: helpful, matching: find.text('Helpful')),
        findsOneWidget,
      );

      // Re-opening the sheet must retain the selected state within this local session.
      await tester.tap(helpful);
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Comments').first)).pop();
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('feed-helpful-sample-student-1')),
          matching: find.text('Helpful · 1'),
        ),
        findsOneWidget,
      );
    },
  );
}
