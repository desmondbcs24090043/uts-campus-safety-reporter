import 'package:flutter/material.dart';

import 'preview_theme.dart';
import 'app_appearance.dart';

/// Presentation-only Profile. User details arrive via the real auth integration.
/// Does not create, edit, or authenticate an account.
class ProfileV2Page extends StatelessWidget {
  const ProfileV2Page({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const Key('profile-v2-list'),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
        children: [
          const _PreviewLabel(),
          const SizedBox(height: 16),
          Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Manage your account and app preferences.',
            style: TextStyle(fontSize: 13.5, color: AdaptivePalette.muted),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: AdaptivePalette.paleBlue,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AdaptivePalette.navy,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student account',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AdaptivePalette.ink,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Email available after account integration',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AdaptivePalette.muted,
                        ),
                      ),
                      SizedBox(height: 10),
                      _RoleTag(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('GENERAL', style: _sectionLabel()),
          const SizedBox(height: 11),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _MenuRow(
                  itemKey: 'profile-open-settings',
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Appearance and app preferences',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsV2Page(),
                    ),
                  ),
                ),
                const _MenuDivider(),
                _MenuRow(
                  itemKey: 'profile-open-help',
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'Using the app and getting help',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const _HelpPage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            key: const Key('profile-sign-out'),
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdaptivePalette.navy,
              backgroundColor: AdaptivePalette.surface,
              side: BorderSide(color: AdaptivePalette.border),
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
          if (onSignOut == null) ...[
            const SizedBox(height: 8),
            Text(
              'Sign out becomes available when authentication is connected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AdaptivePalette.muted),
            ),
          ],
          const SizedBox(height: 20),
          const _DemoNotice(),
        ],
      ),
    );
  }
}

/// Appearance and notification settings for the student preview.
class SettingsV2Page extends StatefulWidget {
  const SettingsV2Page({super.key});

  @override
  State<SettingsV2Page> createState() => _SettingsV2PageState();
}

class _SettingsV2PageState extends State<SettingsV2Page> {
  bool _notificationsPreview = true;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: AppAppearance.darkMode,
    builder: (context, dark, _) => _buildSettings(context, dark),
  );

  Widget _buildSettings(BuildContext context, bool dark) {
    final background = AdaptivePalette.background;
    final surface = AdaptivePalette.surface;
    final foreground = AdaptivePalette.ink;
    final subtle = AdaptivePalette.muted;
    final border = AdaptivePalette.border;
    final accent = AdaptivePalette.navy;

    return Scaffold(
      key: const Key('settings-v2-page'),
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: foreground,
        title: const Text('Settings'),
        titleTextStyle: TextStyle(
          fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              children: [
                Text('APPEARANCE', style: _sectionLabel(color: subtle)),
                const SizedBox(height: 11),
                Container(
                  decoration: _cardDecoration(surface: surface, border: border),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 9, 8, 9),
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode_outlined, color: accent, size: 23),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: TextStyle(
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dark
                                    ? 'Dark mode enabled'
                                    : 'Light mode enabled',
                                style: TextStyle(color: subtle, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          key: const Key('settings-dark-mode-switch'),
                          value: dark,
                          onChanged: AppAppearance.setDarkMode,
                          activeTrackColor: AdaptivePalette.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Appearance applies to all Student App preview screens. This choice is restored when the app restarts.',
                  style: TextStyle(color: subtle, fontSize: 11.5, height: 1.5),
                ),
                const SizedBox(height: 27),
                Text('PREFERENCES', style: _sectionLabel(color: subtle)),
                const SizedBox(height: 11),
                Container(
                  decoration: _cardDecoration(surface: surface, border: border),
                  child: Padding(
                    key: const Key('settings-notifications'),
                    padding: const EdgeInsets.fromLTRB(16, 9, 8, 9),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: accent,
                          size: 23,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _notificationsPreview
                                    ? 'Alerts on (UI preview only)'
                                    : 'Alerts off (UI preview only)',
                                style: TextStyle(color: subtle, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          key: const Key('settings-notifications-switch'),
                          value: _notificationsPreview,
                          onChanged: (value) =>
                              setState(() => _notificationsPreview = value),
                          activeTrackColor: AdaptivePalette.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 27),
                Text('GENERAL', style: _sectionLabel(color: subtle)),
                const SizedBox(height: 11),
                Container(
                  decoration: _cardDecoration(surface: surface, border: border),
                  child: Column(
                    children: [
                      _SettingsRow(
                        itemKey: 'settings-about',
                        icon: Icons.info_outline_rounded,
                        label: 'About App',
                        subtitle: 'Campus Safety Reporter',
                        foreground: foreground,
                        muted: subtle,
                        accent: accent,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _AboutPage(),
                          ),
                        ),
                      ),
                    ],
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

class _RoleTag extends StatelessWidget {
  const _RoleTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AdaptivePalette.paleBlue,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      'STUDENT',
      style: TextStyle(
        color: AdaptivePalette.navy,
        fontWeight: FontWeight.w800,
        letterSpacing: .5,
        fontSize: 9.5,
      ),
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.itemKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String itemKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: Key(itemKey),
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
        child: Row(
          children: [
            Icon(icon, color: AdaptivePalette.navy, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AdaptivePalette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AdaptivePalette.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AdaptivePalette.muted,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    this.itemKey,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.foreground,
    required this.muted,
    required this.accent,
    this.onTap,
  });

  final String? itemKey;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color foreground;
  final Color muted;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: itemKey == null ? null : Key(itemKey!),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(color: muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: muted, size: 20),
          ],
        ),
      ),
    ),
  );
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 17),
    child: Divider(height: 1, color: AdaptivePalette.border),
  );
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AdaptivePalette.paleBlue,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        'DEMO',
        style: TextStyle(
          fontSize: 9,
          letterSpacing: .8,
          fontWeight: FontWeight.w900,
          color: AdaptivePalette.navy,
        ),
      ),
    ),
  );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline_rounded, size: 16, color: AdaptivePalette.muted),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          'UI preview only. Account details are not connected to a live profile.',
          style: TextStyle(
            fontSize: 11.5,
            height: 1.5,
            color: AdaptivePalette.muted,
          ),
        ),
      ),
    ],
  );
}

class _HelpPage extends StatelessWidget {
  const _HelpPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('help-v2-page'),
    backgroundColor: AdaptivePalette.background,
    appBar: AppBar(title: const Text('Help & Support')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            key: const Key('help-v2-list'),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            children: [
              Text(
                'A quick guide to reporting and tracking campus safety issues.',
                style: TextStyle(
                  color: AdaptivePalette.muted,
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 26),
              Text('SAFETY GUIDANCE', style: _sectionLabel()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: AdaptivePalette.warningBg,
                  border: Border.all(color: AdaptivePalette.warningBorder),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AdaptivePalette.warningFg,
                      size: 23,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Urgent situations',
                            style: TextStyle(
                              color: AdaptivePalette.ink,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'For an urgent danger, contact campus security or local emergency services directly. Do not rely on this app for immediate assistance.',
                            style: TextStyle(
                              color: AdaptivePalette.ink,
                              fontSize: 12.5,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 27),
              Text('HOW TO USE THE APP', style: _sectionLabel()),
              const SizedBox(height: 12),
              const _HelpStepCard(
                step: '01',
                icon: Icons.campaign_outlined,
                title: 'Report an issue',
                description: 'Choose a category, describe the issue, and select its location. Add a photo if it helps, then review your details.',
              ),
              const SizedBox(height: 11),
              const _HelpStepCard(
                step: '02',
                icon: Icons.description_outlined,
                title: 'Track your reports',
                description: 'Open My Reports to find a report and check whether its status is Pending, In Progress, or Resolved.',
              ),
              const SizedBox(height: 11),
              const _HelpStepCard(
                step: '03',
                icon: Icons.notifications_none_rounded,
                title: 'Check notifications',
                description: 'Notifications will show report updates when the live notification feature is connected.',
              ),
              const SizedBox(height: 18),
              const _InfoPreviewNote(
                'UI preview only. Submitting reports and delivering live alerts are not connected yet.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('about-v2-page'),
    backgroundColor: AdaptivePalette.background,
    appBar: AppBar(title: const Text('About App')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            key: const Key('about-v2-list'),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AdaptivePalette.paleBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 28,
                        color: AdaptivePalette.navy,
                      ),
                    ),
                    const SizedBox(height: 17),
                    Text(
                      'Campus Safety Reporter',
                      style: TextStyle(
                        color: AdaptivePalette.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'A mobile application for reporting campus safety issues and tracking their status.',
                      style: TextStyle(
                        color: AdaptivePalette.muted,
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Divider(height: 1, color: AdaptivePalette.border),
                    const _AboutMetaRow(label: 'Version', value: '1.0.0'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HelpStepCard extends StatelessWidget {
  const _HelpStepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String step;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDecoration(),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AdaptivePalette.paleBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AdaptivePalette.navy, size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STEP $step',
                style: TextStyle(
                  color: AdaptivePalette.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: AdaptivePalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: TextStyle(
                  color: AdaptivePalette.muted,
                  fontSize: 12.5,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AboutMetaRow extends StatelessWidget {
  const _AboutMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 17),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AdaptivePalette.muted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: AdaptivePalette.ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoPreviewNote extends StatelessWidget {
  const _InfoPreviewNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline_rounded, color: AdaptivePalette.muted, size: 16),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          message,
          style: TextStyle(
            color: AdaptivePalette.muted,
            fontSize: 11.5,
            height: 1.55,
          ),
        ),
      ),
    ],
  );
}

BoxDecoration _cardDecoration({Color? surface, Color? border}) => BoxDecoration(
  color: surface ?? AdaptivePalette.surface,
  border: Border.all(color: border ?? AdaptivePalette.border),
  borderRadius: BorderRadius.circular(23),
);

TextStyle _sectionLabel({Color? color}) => TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w800,
  letterSpacing: 1.5,
  color: color ?? AdaptivePalette.muted,
);
