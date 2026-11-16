import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/notifications_ui.dart';
import 'package:team_repo/preview/preview_theme.dart';
import 'package:team_repo/preview/profile_settings_ui.dart';

void main() {
  testWidgets('Notifications shows sample records and unread filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPreviewTheme(),
        home: const NotificationsV2Page(),
      ),
    );
    expect(find.text('Report received'), findsOneWidget);
    expect(find.text('Unread (2)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications-unread-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Report received'), findsNothing);
    expect(find.text('Report in progress'), findsOneWidget);
  });

  testWidgets('Mark all read produces unread empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPreviewTheme(),
        home: const NotificationsV2Page(),
      ),
    );
    await tester.tap(find.byKey(const Key('notifications-mark-all-read')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notifications-unread-filter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-empty-state')), findsOneWidget);
    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('Tapping a sample notification previews detail and marks read', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPreviewTheme(),
        home: const NotificationsV2Page(),
      ),
    );
    await tester.tap(
      find.byKey(const Key('notifications-item-sample-progress')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-detail-close')), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications-detail-close')));
    await tester.pumpAndSettle();
    expect(find.text('Unread (1)'), findsOneWidget);
  });

  testWidgets(
    'Settings toggles alert preference without opening notification history',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: buildPreviewTheme(), home: const SettingsV2Page()),
      );

      final toggle = find.byKey(const Key('settings-notifications-switch'));
      expect(find.byKey(const Key('settings-notifications')), findsOneWidget);
      expect(tester.widget<Switch>(toggle).value, true);
      expect(find.text('Alerts on (UI preview only)'), findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(toggle).value, false);
      expect(find.text('Alerts off (UI preview only)'), findsOneWidget);
      expect(find.byKey(const Key('notifications-v2-page')), findsNothing);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(toggle).value, true);
    },
  );
}
