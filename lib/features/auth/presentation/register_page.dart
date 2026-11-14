import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../preview/preview_theme.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import 'auth_visuals.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.demoMode = false});

  final bool demoMode;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
    context.read<AuthCubit>().signUp(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageFrame(
      showBack: true,
      demoMode: widget.demoMode,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated && state.message != null) {
            Navigator.of(context).pop();
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create your account',
                style: TextStyle(
                  color: PreviewColours.ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Join Campus Safety to report and track issues.',
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
                        key: const Key('auth-register-email'),
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
                        key: const Key('auth-register-password'),
                        controller: _password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!loading) _submit();
                        },
                        autofillHints: const [AutofillHints.newPassword],
                        style: const TextStyle(color: PreviewColours.ink),
                        decoration: authInputDecoration(
                          hint: 'At least 6 characters',
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
                        title: 'Create account',
                        buttonKey: const Key('auth-create-account'),
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
                      'Already have an account?',
                      style: TextStyle(color: PreviewColours.muted),
                    ),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign in',
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
