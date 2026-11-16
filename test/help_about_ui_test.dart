import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/preview_theme.dart';
import 'package:team_repo/preview/profile_settings_ui.dart';

void main() {
  testWidgets('Profile opens a useful Help & Support guide', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPreviewTheme(),
        home: const Scaffold(body: ProfileV2Page()),
      ),
    );

    await tester.tap(find.byKey(const Key('profile-open-help')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('help-v2-page')), findsOneWidget);
    expect(find.text('Report an issue'), findsOneWidget);
    expect(find.text('Track your reports'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Urgent situations'),
      180,
      scrollable: find.descendant(
        of: find.byKey(const Key('help-v2-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.textContaining('urgent danger'), findsOneWidget);
  });

  testWidgets('Settings opens About App with grounded project details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPreviewTheme(),
        home: const Scaffold(body: ProfileV2Page()),
      ),
    );

    await tester.tap(find.byKey(const Key('profile-open-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('settings-about')));
    await tester.tap(find.byKey(const Key('settings-about')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('about-v2-page')), findsOneWidget);
    expect(find.text('Campus Safety Reporter'), findsOneWidget);
    expect(
      find.textContaining('A mobile application for reporting'),
      findsOneWidget,
    );
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('Built with'), findsNothing);
    expect(find.text('Project status'), findsNothing);
    expect(find.text('UI preview'), findsNothing);
  });
}
