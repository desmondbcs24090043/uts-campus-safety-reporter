import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/app_appearance.dart';
import 'package:team_repo/preview/preview_theme.dart';
import 'package:team_repo/preview/profile_settings_ui.dart';

void main() {
  setUp(() => AppAppearance.setDarkMode(false));

  testWidgets('Dark Mode toggle updates the shared MaterialApp theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: AppAppearance.darkMode,
        builder: (context, dark, _) => MaterialApp(
          theme: buildPreviewTheme(dark: false),
          darkTheme: buildPreviewTheme(dark: true),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: const SettingsV2Page(),
        ),
      ),
    );
    expect(
      Theme.of(tester.element(find.byKey(const Key('settings-v2-page'))))
          .brightness,
      Brightness.light,
    );
    await tester.tap(find.byKey(const Key('settings-dark-mode-switch')));
    await tester.pumpAndSettle();
    expect(AppAppearance.isDark, true);
    expect(
      Theme.of(tester.element(find.byKey(const Key('settings-v2-page'))))
          .brightness,
      Brightness.dark,
    );
    await tester.ensureVisible(find.byKey(const Key('settings-about')));
    await tester.tap(find.byKey(const Key('settings-about')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('about-v2-page')), findsOneWidget);
    final about = tester.widget<Scaffold>(
      find.byKey(const Key('about-v2-page')),
    );
    expect(about.backgroundColor, AdaptivePalette.background);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-dark-mode-switch')));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byKey(const Key('settings-v2-page'))))
          .brightness,
      Brightness.light,
    );
  });
}
