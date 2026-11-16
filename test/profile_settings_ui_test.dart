import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/preview_theme.dart';
import 'package:team_repo/preview/profile_settings_ui.dart';
import 'package:team_repo/preview/app_appearance.dart';

void main() {
  setUp(() => AppAppearance.setDarkMode(false));

  testWidgets('Profile navigates to settings and toggles dark preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPreviewTheme(),
        home: const Scaffold(body: ProfileV2Page()),
      ),
    );
    expect(find.text('Student account'), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-open-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-v2-page')), findsOneWidget);
    final toggle = find.byKey(const Key('settings-dark-mode-switch'));
    expect(tester.widget<Switch>(toggle).value, false);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, true);
    expect(find.text('Dark mode enabled'), findsOneWidget);
  });

  testWidgets('Profile opens help and calls real sign-out callback', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPreviewTheme(),
        home: Scaffold(body: ProfileV2Page(onSignOut: () => calls++)),
      ),
    );
    await tester.tap(find.byKey(const Key('profile-open-help')));
    await tester.pumpAndSettle();
    expect(find.textContaining('urgent danger'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-sign-out')));
    await tester.tap(find.byKey(const Key('profile-sign-out')));
    expect(calls, 1);
  });
}
