import 'package:flutter/material.dart';

import '../../../preview/preview_theme.dart';

/// Shared, presentation-only styling for the Campus Safety auth screens.
/// Kept separate from authentication state and repository logic.
class AuthPageFrame extends StatelessWidget {
  const AuthPageFrame({
    super.key,
    required this.child,
    this.demoMode = false,
    this.showBack = false,
  });

  final Widget child;
  final bool demoMode;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PreviewColours.background,
      appBar: showBack
          ? AppBar(
              backgroundColor: PreviewColours.background,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Back to sign in',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: PreviewColours.ink),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: PreviewColours.navy,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CAMPUS SAFETY',
                              style: TextStyle(
                                color: PreviewColours.muted,
                                fontSize: 10,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Reporter',
                              style: TextStyle(
                                color: PreviewColours.ink,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (demoMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: PreviewColours.paleBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'DEMO',
                            style: TextStyle(
                              fontSize: 10,
                              color: PreviewColours.navy,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  child,
                  if (demoMode) ...[
                    const SizedBox(height: 25),
                    const Center(
                      child: Text(
                        'Demo preview only. Sign-in is not connected to Supabase.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: PreviewColours.muted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFormPanel extends StatelessWidget {
  const AuthFormPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: PreviewColours.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PreviewColours.deepNavy.withValues(alpha: .035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: PreviewColours.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

InputDecoration authInputDecoration({
  required String hint,
  Widget? suffixIcon,
}) {
  const normal = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(15)),
    borderSide: BorderSide(color: PreviewColours.border),
  );
  const focused = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(15)),
    borderSide: BorderSide(color: PreviewColours.blue, width: 1.6),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: PreviewColours.muted, fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    border: normal,
    enabledBorder: normal,
    focusedBorder: focused,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    suffixIcon: suffixIcon,
  );
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    required this.loading,
    required this.buttonKey,
  });

  final String title;
  final VoidCallback? onPressed;
  final bool loading;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        key: buttonKey,
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: PreviewColours.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PreviewColours.navy.withValues(alpha: .6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 19,
                width: 19,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
