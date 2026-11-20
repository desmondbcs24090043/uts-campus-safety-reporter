// Student LIVE AUTH + MY REPORTS integration (separate opt-in entry point).
// It does NOT submit reports or upload media yet. Those screens remain demos.
// Run: flutter run -d chrome -t lib/live_student_main.dart
//      --dart-define-from-file=env.json
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/supabase_config.dart';
import 'data/models/user_role.dart';
import 'data/repositories/incident_report_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/auth_state.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/reports/data/supabase_reports_adapter.dart';
import 'features/reports/presentation/reports_bloc.dart';
import 'features/reports/presentation/reports_event.dart';
import 'preview/app_appearance.dart';
import 'preview/preview_theme.dart';
import 'preview_integrated/preview_app_integrated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppAppearance.restore();

  // A valid local configuration must be supplied at run/build time.
  if (!SupabaseConfig.isConfigured ||
      SupabaseConfig.url.contains('YOUR-') ||
      SupabaseConfig.publishableKey.contains('xxx_or_legacy') ||
      SupabaseConfig.publishableKey.contains('your-real-public-key')) {
    runApp(
      const _StartupMessage(
        'Supabase is not configured.\n\nFill your local env.json with the '
        'team Project URL and publishable key, then run with '
        '--dart-define-from-file=env.json.\n\nDo not use a secret or service_role key.',
      ),
    );
    return;
  }

  try {
    await SupabaseConfig.initialize();
  } catch (_) {
    runApp(
      const _StartupMessage(
        'Unable to initialise Supabase. Check the local configuration '
        'and your network connection.',
      ),
    );
    return;
  }

  runApp(
    BlocProvider<AuthCubit>(
      create: (_) => _LiveStudentAuthCubit()..restoreSession(),
      child: const _LiveStudentGate(),
    ),
  );
}

class _LiveStudentAuthCubit extends AuthCubit {
  _LiveStudentAuthCubit() : super(SupabaseAuthRepository());

  Future<void> restoreSession() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentUser == null) return;
    emit(const AuthLoading());
    try {
      final role = await ProfileRepository().fetchMyRole();
      if (role == UserRole.student) {
        emit(const AuthAuthenticated(role: 'student'));
      } else {
        await auth.signOut();
        emit(
          const AuthUnauthenticated(
            message: 'Staff accounts must use the Web Admin portal.',
          ),
        );
      }
    } catch (_) {
      // A failed role check never grants access to student reports.
      emit(const AuthUnauthenticated());
    }
  }
}

class _LiveStudentGate extends StatelessWidget {
  const _LiveStudentGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated && state.role == 'student') {
          final reports = IncidentReportRepository();
          final auth = Supabase.instance.client.auth;
          return BlocProvider<ReportsBloc>(
            create: (_) =>
                ReportsBloc(SupabaseReportsAdapter(reports))
                  ..add(const ReportsRequested()),
            child: CampusSafetyIntegratedPreviewApp(
              reportDetailsBuilder: (reportId) => LiveStudentReportDetailsPage(
                reportId: reportId,
                repository: reports,
                currentUserId: () => auth.currentUser?.id,
                identityChanges: auth.onAuthStateChange.map(
                  (event) => event.session?.user.id,
                ),
              ),
              onSignOut: () => context.read<AuthCubit>().signOut(),
            ),
          );
        }
        return MaterialApp(
          title: 'Campus Safety Reporter - Student',
          debugShowCheckedModeBanner: false,
          theme: buildPreviewTheme(dark: false),
          darkTheme: buildPreviewTheme(dark: true),
          themeMode: AppAppearance.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const LoginPage(demoMode: false),
        );
      },
    );
  }
}

class _StartupMessage extends StatelessWidget {
  const _StartupMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
