import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/preview_theme.dart';
import 'package:team_repo/preview/report_issue_ui.dart';

void main() {
  Future<void> openReport(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildPreviewTheme(), home: const ReportIssuePreviewPage()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollFormTo(WidgetTester tester, String keyName) async {
    await tester.scrollUntilVisible(
      find.byKey(Key(keyName)),
      190,
      scrollable: find.descendant(
        of: find.byKey(const Key('report-issue-form')),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Report UI retains five agreed incident categories', (tester) async {
    await openReport(tester);
    expect(find.text('Report an issue'), findsOneWidget);
    for (final label in [
      'Safety Hazard', 'Facility Damage', 'Suspicious Activity', 'Lighting', 'Other'
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Report UI requires category before review', (tester) async {
    await openReport(tester);
    await tester.tap(find.byKey(const Key('report-preview-review')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a category first.'), findsOneWidget);
  });

  testWidgets('Location UI provides GPS and map choices', (tester) async {
    await openReport(tester);
    await scrollFormTo(tester, 'use-gps-preview');
    expect(find.text('Use GPS'), findsOneWidget);
    expect(find.text('Choose on map'), findsOneWidget);
    expect(find.text('ILLUSTRATIVE MAP'), findsNothing);
    await tester.tap(find.byKey(const Key('use-gps-preview')));
    await tester.pumpAndSettle();
    await scrollFormTo(tester, 'report-location-panel');
    expect(find.text('Demo location selected'), findsOneWidget);
  });

  testWidgets('Report can be edited and preview completed', (tester) async {
    await openReport(tester);

    // Confirm the category is actually selected, not just tapped.
    const categoryKey = Key('category-safety_hazard');
    await tester.tap(find.byKey(categoryKey));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(categoryKey)).selected, isTrue,
        reason: 'The Safety Hazard category did not become selected.');

    await scrollFormTo(tester, 'report-description');
    const reportDescription = 'Broken light near the library entrance.';
    await tester.enterText(
      find.byKey(const Key('report-description')), reportDescription,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byKey(const Key('report-description')))
          .controller?.text,
      reportDescription,
      reason: 'The description controller did not receive the entered text.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    const reviewKey = Key('report-preview-review');
    await tester.tap(find.byKey(reviewKey));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a campus area before reviewing your report.'),
      findsOneWidget,
    );
    expect(find.text('Review your report'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await scrollFormTo(tester, 'report-campus-area');
    await tester.tap(find.byKey(const Key('report-campus-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo area B').last);
    await tester.pumpAndSettle();

    // Campus Area alone is sufficient. Leave both the optional field and aids unused.

    await tester.tap(find.byKey(reviewKey));
    await tester.pumpAndSettle();

    if (find.text('Review your report').evaluate().isEmpty) {
      final messages = tester.widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .where((text) =>
              text.contains('Choose a category') ||
              text.contains('location') ||
              text.contains('characters') ||
              text.contains('Description'))
          .toList();
      debugPrint('DIAGNOSTIC: Review dialog absent. Visible messages: $messages');
    }
    expect(find.text('Review your report'), findsOneWidget,
        reason: 'Review dialog not shown after selecting category, valid text, and sample location.');
    expect(find.text('No photo attached'), findsWidgets);
    expect(find.text('Campus Area'), findsOneWidget);
    expect(find.text('Demo coordinates'), findsNothing);
    expect(find.byKey(const Key('edit-report-preview')), findsOneWidget);
    expect(find.byKey(const Key('finish-demo-report')), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-report-preview')));
    await tester.pumpAndSettle();
    expect(find.byKey(reviewKey), findsOneWidget);

    await tester.tap(find.byKey(reviewKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finish-demo-report')));
    await tester.pumpAndSettle();
    expect(find.text('UI preview complete'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
    expect(find.textContaining('No report was submitted.'), findsOneWidget);
  });
}