import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:team_repo/features/auth/data/mock_auth_repository.dart';
import 'package:team_repo/features/auth/presentation/auth_cubit.dart';
import 'package:team_repo/preview_auth_dashboard_main.dart';

void main() {
  testWidgets('Student can sign in, open Dashboard and sign out', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthCubit(MockAuthRepository()),
        child: const AuthDashboardPreview(),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('auth-sign-in')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'student@test.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'Test1234!');

    await tester.ensureVisible(find.byKey(const Key('auth-sign-in')));
    await tester.tap(find.byKey(const Key('auth-sign-in')));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Student 👋'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-sign-out')),
      150,
      scrollable: find.descendant(
        of: find.byKey(const Key('profile-v2-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('profile-sign-out')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Hello, Student 👋'), findsNothing);
  });

  testWidgets('Registration screen opens with matching branding', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthCubit(MockAuthRepository()),
        child: const AuthDashboardPreview(),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('auth-open-register')));
    await tester.tap(find.byKey(const Key('auth-open-register')));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.byKey(const Key('auth-create-account')), findsOneWidget);

    await tester.tap(find.byTooltip('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
