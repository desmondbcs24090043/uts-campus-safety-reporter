import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:team_repo/features/auth/data/mock_auth_repository.dart';
import 'package:team_repo/features/auth/presentation/auth_cubit.dart';
import 'package:team_repo/preview_auth_dashboard_main.dart';

void main() {
  testWidgets(
    'Student can log in, open Dashboard and sign out',
    (tester) async {
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => AuthCubit(MockAuthRepository()),
          child: const AuthDashboardPreview(),
        ),
      );

      // Login
      expect(find.text('SECURE LOGIN'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'student@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Test1234!',
      );

      await tester.ensureVisible(find.text('SECURE LOGIN'));
      await tester.tap(find.text('SECURE LOGIN'));
      await tester.pumpAndSettle();

      // Student Dashboard
      expect(find.text('Hello, Student 👋'), findsOneWidget);

      // Profile
      await tester.tap(
        find.byKey(const Key('nav-profile')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('profile-sign-out')),
        findsOneWidget,
      );

      // Sign out
      await tester.tap(
        find.byKey(const Key('profile-sign-out')),
      );
      await tester.pumpAndSettle();

      // Back to Login
      expect(find.text('SECURE LOGIN'), findsOneWidget);
      expect(find.text('Hello, Student 👋'), findsNothing);
    },
  );
}