import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../preview/preview_theme.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import 'auth_visuals.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.demoMode = false});

  /// True only for the independent Member 2 mock-auth preview.
  final bool demoMode;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthCubit>().signIn(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageFrame(
      demoMode: widget.demoMode,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is AuthUnauthenticated && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(
                  color: PreviewColours.ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to report and track campus issues.',
                style: TextStyle(
                  color: PreviewColours.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              AuthFormPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthFieldLabel('Email address'),
                      const SizedBox(height: 9),
                      TextFormField(
                        key: const Key('auth-email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(color: PreviewColours.ink),
                        decoration: authInputDecoration(
                          hint: 'Enter your email address',
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      const AuthFieldLabel('Password'),
                      const SizedBox(height: 9),
                      TextFormField(
                        key: const Key('auth-password'),
                        controller: _password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!loading) _submit();
                        },
                        autofillHints: const [AutofillHints.password],
                        style: const TextStyle(color: PreviewColours.ink),
                        decoration: authInputDecoration(
                          hint: 'Enter your password',
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: PreviewColours.muted,
                              size: 21,
                            ),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 26),
                      AuthPrimaryButton(
                        title: 'Sign in',
                        buttonKey: const Key('auth-sign-in'),
                        loading: loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  spacing: 3,
                  children: [
                    const Text(
                      'New here?',
                      style: TextStyle(color: PreviewColours.muted),
                    ),
                    TextButton(
                      key: const Key('auth-open-register'),
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => RegisterPage(
                                    demoMode: widget.demoMode,
                                  ),
                                ),
                              ),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          color: PreviewColours.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
