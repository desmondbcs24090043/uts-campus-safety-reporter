import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Staff sign-in. Role authorisation remains in AdminAuthGate.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading || _formKey.currentState?.validate() != true) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // AdminAuthGate handles admin authorisation after sign-in.
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not connect. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: _LoginFormCard(
                formKey: _formKey,
                email: _email,
                password: _password,
                loading: _loading,
                hidePassword: _hidePassword,
                error: _error,
                onTogglePassword: () =>
                    setState(() => _hidePassword = !_hidePassword),
                onSubmit: _login,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.email,
    required this.password,
    required this.loading,
    required this.hidePassword,
    required this.error,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final bool hidePassword;
  final String? error;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 38),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: scheme.onPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campus Safety Reporter',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'STAFF WORKSPACE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.3,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 31),
              Text('Welcome back', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 9),
              Text(
                'Sign in to manage campus incident reports.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 34),
              Text('Email address', style: theme.textTheme.labelLarge),
              const SizedBox(height: 9),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'Enter your staff email',
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 22),
              Text('Password', style: theme.textTheme.labelLarge),
              const SizedBox(height: 9),
              TextFormField(
                controller: password,
                obscureText: hidePassword,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    tooltip: hidePassword ? 'Show password' : 'Hide password',
                    onPressed: onTogglePassword,
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your password'
                    : null,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: 27),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : onSubmit,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Authorised campus staff only',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
