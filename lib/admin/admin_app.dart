import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/user_role.dart';
import '../data/repositories/profile_repository.dart';
import 'pages/admin_login_page.dart';
import 'pages/report_list_page.dart';

/// Root widget of the Web Admin.
/// TODO(Member 2): replace the theme with the team's shared design system.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UTS Campus Safety - Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4E79)),
        useMaterial3: true,
      ),
      home: const AdminAuthGate(),
    );
  }
}

/// Decides what to show based on the login session:
///   not logged in      -> login page
///   logged in, admin   -> report list
///   logged in, student -> "access denied" (and the database would block
///                          them anyway, thanks to RLS)
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) return const AdminLoginPage();
        // Key by user id so the role is re-checked when the user changes.
        return _RoleCheck(key: ValueKey(session.user.id));
      },
    );
  }
}

class _RoleCheck extends StatefulWidget {
  const _RoleCheck({super.key});

  @override
  State<_RoleCheck> createState() => _RoleCheckState();
}

class _RoleCheckState extends State<_RoleCheck> {
  late Future<UserRole?> _role = ProfileRepository().fetchMyRole();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: _role,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return _Message(
            icon: Icons.cloud_off,
            text: 'Could not check your account.\n${snapshot.error}',
            actionLabel: 'Retry',
            onAction: () =>
                setState(() => _role = ProfileRepository().fetchMyRole()),
          );
        }
        if (snapshot.data == UserRole.admin) return const ReportListPage();
        return _Message(
          icon: Icons.block,
          text: 'Access denied.\nThis portal is for campus safety staff only.',
          actionLabel: 'Log out',
          onAction: () => Supabase.instance.client.auth.signOut(),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
