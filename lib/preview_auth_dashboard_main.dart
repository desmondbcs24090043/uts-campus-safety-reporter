import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/data/mock_auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/auth_state.dart';
import 'features/auth/presentation/login_page.dart';

import 'features/reports/data/demo_reports_repository.dart';
import 'features/reports/presentation/reports_bloc.dart';
import 'features/reports/presentation/reports_event.dart';
import 'preview_integrated/preview_app_integrated.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    BlocProvider(
      create: (_) => AuthCubit(MockAuthRepository()),
      child: const AuthDashboardPreview(),
    ),
  );
}

class AuthDashboardPreview extends StatelessWidget {
  const AuthDashboardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.role == 'student') {
            return BlocProvider(
              create: (_) => ReportsBloc(
                DemoReportsRepository(),
              )..add(const ReportsRequested()),
              child: CampusSafetyIntegratedPreviewApp(
                onSignOut: () => context.read<AuthCubit>().signOut(),
              ),
            );
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Admin dashboard is not integrated yet.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AuthCubit>().signOut(),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Campus Safety Reporter',
          home: LoginPage(demoMode: true),
        );
      },
    );
  }
}
