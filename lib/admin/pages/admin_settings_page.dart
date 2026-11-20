import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin_appearance.dart';

/// Functional staff settings: authenticated account details and appearance.
/// Appearance is session-only; no preferences table or extra API is required.
class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final account = Supabase.instance.client.auth.currentUser;
    final email = account?.email ?? 'Not available';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace settings',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage how the staff workspace looks and review your signed-in account.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'My account',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Signed-in email',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 7),
                        SelectableText(
                          email,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Access',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text('Campus safety staff'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.palette_outlined, color: scheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Appearance',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Choose a theme for the Admin workspace.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        AnimatedBuilder(
                          animation: AdminAppearance.instance,
                          builder: (context, _) => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final option in const [
                                (
                                  ThemeMode.system,
                                  'System',
                                  Icons.brightness_auto_outlined,
                                ),
                                (
                                  ThemeMode.light,
                                  'Light',
                                  Icons.light_mode_outlined,
                                ),
                                (
                                  ThemeMode.dark,
                                  'Dark',
                                  Icons.dark_mode_outlined,
                                ),
                              ])
                                ChoiceChip(
                                  avatar: Icon(option.$3, size: 18),
                                  label: Text(option.$2),
                                  selected:
                                      AdminAppearance.instance.themeMode ==
                                      option.$1,
                                  onSelected: (_) => AdminAppearance.instance
                                      .setThemeMode(option.$1),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your selection lasts for this app session.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('About', style: theme.textTheme.titleLarge),
                              const SizedBox(height: 7),
                              Text(
                                'Campus Safety Reporter · Staff workspace',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
