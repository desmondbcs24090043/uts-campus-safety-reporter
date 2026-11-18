import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/preview_theme.dart';
import 'package:team_repo/preview/profile_settings_ui.dart';

void main() {
  testWidgets('Settings has no separate Privacy & Permissions entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildPreviewTheme(), home: const SettingsV2Page()),
    );
    expect(find.byKey(const Key('settings-v2-page')), findsOneWidget);
    expect(find.byKey(const Key('settings-privacy')), findsNothing);
    expect(find.text('Privacy & Permissions'), findsNothing);
    expect(find.byKey(const Key('settings-notifications')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('settings-about')));
    expect(find.byKey(const Key('settings-about')), findsOneWidget);
  });

  testWidgets('About App still opens after Privacy entry removal', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildPreviewTheme(), home: const SettingsV2Page()),
    );
    await tester.ensureVisible(find.byKey(const Key('settings-about')));
    await tester.tap(find.byKey(const Key('settings-about')));
    await tester.pumpAndSettle();
    expect(find.text('About App'), findsWidgets);
    expect(
      find.textContaining('reporting campus safety issues'),
      findsOneWidget,
    );
  });
}
