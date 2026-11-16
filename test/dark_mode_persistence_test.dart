import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_repo/preview/app_appearance.dart';
import 'package:team_repo/preview_auth_dashboard_main.dart' as preview;

void main() {
  testWidgets('First launch and subsequent launches restore the saved theme', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() {
      AppAppearance.darkMode.value = false;
      SharedPreferences.setMockInitialValues({});
    });

    Future<void> launch() async {
      await tester.pumpWidget(const SizedBox.shrink());
      // Discard the Flutter process's in-memory theme and preference cache.
      AppAppearance.darkMode.value = false;
      SharedPreferences.resetStatic();
      await preview.main();
      await tester.pumpAndSettle();
    }

    Brightness loginBrightness() =>
        Theme.of(tester.element(find.byKey(const Key('auth-email'))))
            .brightness;

    await launch();
    expect(loginBrightness(), Brightness.light);

    for (final enabled in [true, false]) {
      await tester.enterText(
        find.byKey(const Key('auth-email')),
        'student@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('auth-password')),
        'Test1234!',
      );
      await tester.ensureVisible(find.byKey(const Key('auth-sign-in')));
      await tester.tap(find.byKey(const Key('auth-sign-in')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-open-settings')));
      await tester.pumpAndSettle();
      final toggle = find.byKey(const Key('settings-dark-mode-switch'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(toggle).value, enabled);
      expect(
        (await SharedPreferences.getInstance()).getBool('student.dark_mode'),
        enabled,
      );

      await launch();
      expect(loginBrightness(), enabled ? Brightness.dark : Brightness.light);
    }
  });
}
