import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/features/auth/data/mock_auth_repository.dart';
import 'package:team_repo/features/auth/presentation/auth_cubit.dart';
import 'package:team_repo/preview/app_appearance.dart';
import 'package:team_repo/preview_auth_dashboard_main.dart';

Finder keyed(String value) => find.byKey(Key(value));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final screenshotDirectory = Platform.environment['CAMPUS_QA_SCREENSHOTS'];
  final fontDirectory = Platform.environment['CAMPUS_QA_FONT_DIRECTORY'];

  if (fontDirectory != null) {
    setUpAll(() async {
      // Use the SDK's text and icon fonts for optional visual QA captures.
      final families = {
        'Ahem': ['roboto-regular.ttf'],
        'Roboto': ['roboto-regular.ttf', 'roboto-bold.ttf', 'roboto-black.ttf'],
        'MaterialIcons': ['materialicons-regular.otf'],
      };
      for (final MapEntry(key: family, value: files) in families.entries) {
        final loader = FontLoader(family);
        for (final name in files) {
          final bytes = await File('$fontDirectory/$name').readAsBytes();
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
        }
        await loader.load();
      }
    });
  }

  const sizes = [
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
  ];

  for (final size in sizes) {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';
      final width = size.width.toInt();
      testWidgets(
        'Student navigation and controls at $width px in $mode mode',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
          AppAppearance.darkMode.value = dark;
          addTearDown(() {
            tester.view.reset();
            AppAppearance.darkMode.value = false;
          });

          final capture = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: BlocProvider(
                create: (_) => AuthCubit(MockAuthRepository()),
                child: const AuthDashboardPreview(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          Future<void> page(String name, Finder landmark) async {
            expect(tester.takeException(), isNull, reason: name);
            expect(landmark.hitTestable(), findsOneWidget, reason: name);
            if (screenshotDirectory == null) return;
            final boundary =
                capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = boundary.toImageSync();
            try {
              await tester.runAsync(() async {
                final bytes = (await image.toByteData(
                  format: ui.ImageByteFormat.png,
                ))!;
                final directory = Directory(
                  '$screenshotDirectory/$width-$mode',
                );
                await directory.create(recursive: true);
                await File('${directory.path}/$name.png').writeAsBytes(
                  bytes.buffer.asUint8List(
                    bytes.offsetInBytes,
                    bytes.lengthInBytes,
                  ),
                );
              });
            } finally {
              image.dispose();
            }
          }

          Future<void> tap(Finder control) async {
            await tester.ensureVisible(control);
            await tester.pumpAndSettle();
            expect(control.hitTestable(), findsOneWidget);
            await tester.tap(control);
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'After tapping $control',
            );
          }

          Future<void> back() async {
            await tester.pageBack();
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          Future<void> checkPasswordVisibility() async {
            await tap(find.byTooltip('Show password'));
            expect(find.byTooltip('Hide password'), findsOneWidget);
            await tap(find.byTooltip('Hide password'));
            expect(find.byTooltip('Show password'), findsOneWidget);
          }

          Future<void> revealInList(
            String list,
            Finder control, {
            double delta = 140,
            double alignment = 0,
          }) async {
            await tester.scrollUntilVisible(
              control,
              delta,
              scrollable: find
                  .descendant(
                    of: keyed(list),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
              await Scrollable.ensureVisible(tester.element(control), alignment: alignment);
              await tester.pumpAndSettle();
          }

          Future<void> formControl(String key) async {
            await revealInList('report-issue-form', keyed(key));
            await tap(keyed(key));
          }

          Future<void> sheetButton(String key) async {
            final sheetScroll = find.descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            );
            expect(sheetScroll, findsOneWidget);
            await tester.scrollUntilVisible(
              keyed(key),
              100,
              scrollable: sheetScroll,
            );
            await tap(keyed(key));
          }

          await page('01-login', find.text('Welcome back'));
          expect(
            Theme.of(tester.element(keyed('auth-email'))).brightness,
            dark ? Brightness.dark : Brightness.light,
          );
          await checkPasswordVisibility();
          await tap(keyed('auth-open-register'));
          await page('02-register', find.text('Create your account'));
          await checkPasswordVisibility();
          await tester.ensureVisible(keyed('auth-create-account'));
          expect(keyed('auth-create-account').hitTestable(), findsOneWidget);
          await tap(find.byTooltip('Back to sign in'));
          await tester.enterText(keyed('auth-email'), 'student@test.com');
          await tester.enterText(keyed('auth-password'), 'Test1234!');
          await tap(keyed('auth-sign-in'));

          await page('03-dashboard', find.text('Hello, Student 👋'));
          final pending = keyed('dashboard-pending-summary');
          await revealInList('dashboard-list', pending, alignment: .65);
          await page('03a-dashboard-status', pending);
          await tap(keyed('nav-reports'));
          await page('04-my-reports', keyed('reports-search'));
          await tester.enterText(keyed('reports-search'), 'chair');
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          final pendingFilter = keyed('filter-pending');
          await revealInList('my-reports-list', pendingFilter);
          await tap(pendingFilter);
          await revealInList('my-reports-list', find.text('1 reports'));
          expect(find.text('1 reports'), findsOneWidget);
          final report = keyed('report-card-CSR-2026-003');
          await revealInList('my-reports-list', report);
          await tap(report);
          await page('05-report-details', find.text('Report Details'));
          final noPhoto = find.text('No photo attached');
          await revealInList('report-details', noPhoto);
          expect(noPhoto.hitTestable(), findsOneWidget);
          await back();
          await tap(keyed('nav-home'));
          final sample = keyed('report-card-CSR-2026-001');
          await revealInList('dashboard-list', sample);
          await tap(sample);
          final thumbnail = keyed('report-photo-thumbnail');
          await revealInList('report-details', thumbnail, alignment: .76);
          final photoContext = tester.element(thumbnail);
          await tester.runAsync(() => precacheImage(
            const AssetImage('assets/demo/corridor-light.jpg'),
            photoContext,
          ));
          await tester.pumpAndSettle();
          await page('05a-attached-photo', thumbnail);
          await tap(thumbnail);
          await page('05b-photo-viewer', keyed('report-photo-viewer'));
          await tap(find.byTooltip('Close photo'));
          await back();
          final reportIssue = keyed('report-issue-cta');
          await revealInList('dashboard-list', reportIssue, delta: -140);
          await tap(reportIssue);
          await page('06-report-an-issue', keyed('report-preview-review'));
          await formControl('category-safety_hazard');
          await revealInList('report-issue-form', keyed('report-description'));
          await tester.enterText(
            keyed('report-description'),
            'Broken light near the library entrance.',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await formControl('report-campus-area');
          await tap(find.text('Demo area A').last);
          await revealInList(
            'report-issue-form',
            keyed('report-specific-location'),
            alignment: .46,
          );
          await tester.enterText(
            keyed('report-specific-location'),
            'Beside the stairwell',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await page('06d-location-fields', keyed('report-specific-location'));
          await formControl('choose-map-preview');
          await page('06a-location-sheet', find.text('Choose a location'));
          await sheetButton('confirm-demo-map-pin');
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
          await tap(keyed('report-preview-review'));
          await page('06b-review-sheet', find.text('Review your report'));
          expect(find.text('Beside the stairwell'), findsWidgets);
          expect(find.text('Demo coordinates'), findsOneWidget);
          await sheetButton('finish-demo-report');
          await page('06c-report-complete', find.text('UI preview complete'));
          await tap(keyed('report-preview-home'));

          final notifications = keyed('notifications-button');
          await revealInList('dashboard-list', notifications, delta: -140);
          await tap(notifications);
          await page('07-notifications', find.text('Notifications'));
          await tap(keyed('notifications-unread-filter'));
          final notification = keyed('notifications-item-sample-progress');
          await revealInList('notifications-list', notification);
          await tap(notification);
          await page(
            '07a-notification-sheet',
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text('Report in progress'),
            ),
          );
          await sheetButton('notifications-detail-close');
          final markAllRead = keyed('notifications-mark-all-read');
          await revealInList('notifications-list', markAllRead, delta: -140);
          await tap(markAllRead);
          expect(keyed('notifications-empty-state'), findsOneWidget);
          await back();

          await tap(keyed('nav-profile'));
          await page(
            '08-profile',
            find.text('Manage your account and app preferences.'),
          );
          final help = keyed('profile-open-help');
          await revealInList('profile-v2-list', help);
          await tap(help);
          await page('10-help-and-support', find.text('Help & Support'));
          await tester.scrollUntilVisible(
            find.text('Urgent situations'),
            140,
            scrollable: find.descendant(
              of: keyed('help-v2-list'),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Urgent situations').hitTestable(), findsOneWidget);
          await back();
          final settings = keyed('profile-open-settings');
          await revealInList('profile-v2-list', settings, delta: -140);
          await tap(settings);
          await page('09-settings', find.text('Settings'));
          final alerts = keyed('settings-notifications-switch');
          await revealInList('settings-v2-page', alerts);
          await tap(alerts);
          expect(tester.widget<Switch>(alerts).value, isFalse);
          await tap(alerts);
          expect(tester.widget<Switch>(alerts).value, isTrue);
          final appearance = keyed('settings-dark-mode-switch');
          await revealInList('settings-v2-page', appearance, delta: -140);
          await tap(appearance);
          expect(tester.widget<Switch>(appearance).value, !dark);
          await tap(appearance);
          expect(tester.widget<Switch>(appearance).value, dark);
          final about = keyed('settings-about');
          await revealInList('settings-v2-page', about);
          await tap(about);
          await page('11-about-app', find.text('About App'));
          await back();
          await back();
          await revealInList('profile-v2-list', keyed('profile-sign-out'));
          await tap(keyed('profile-sign-out'));
          expect(find.text('Welcome back'), findsOneWidget);
        },
      );
    }
  }
}
