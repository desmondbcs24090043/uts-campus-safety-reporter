import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/incident_report.dart';
import '../../data/models/report_status.dart';
import '../../data/repositories/incident_report_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../widgets/status_chip.dart';
import 'report_detail_page.dart';
import 'admin_settings_page.dart';

/// Staff dashboard. All displayed data comes from the shared repository.
class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key, this.repository});

  final IncidentReportRepository? repository;

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  late final IncidentReportRepository _repo =
      widget.repository ?? IncidentReportRepository();
  final _pageScroll = ScrollController();
  final _reportsKey = GlobalKey();

  ReportStatus? _filter;
  String _search = '';
  bool _navReports = false;
  bool _loading = true;
  String? _error;
  List<IncidentReport> _reports = const [];
  Map<ReportStatus, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.fetchReports(status: _filter, limit: 200),
        _repo.countByStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _reports = results[0] as List<IncidentReport>;
        _counts = results[1] as Map<ReportStatus, int>;
        _loading = false;
      });
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load reports. Please try again.';
      });
    }
  }

  void _setFilter(ReportStatus? status) {
    if (_filter == status) return;
    setState(() => _filter = status);
    _load();
  }

  Future<void> _open(IncidentReport report) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ReportDetailPage(reportId: report.id, repository: _repo),
      ),
    );
    if (mounted) _load();
  }

  void _jumpToOverview() {
    setState(() => _navReports = false);
    if (_pageScroll.hasClients) {
      _pageScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
  }

  void _jumpToReports() {
    setState(() => _navReports = true);
    final target = _reportsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        alignment: 0.04,
      );
    }
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AdminSettingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final compactActions = MediaQuery.sizeOf(context).width < 680;
    final total = _counts.values.fold<int>(0, (sum, count) => sum + count);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 24,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF153C79),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Campus Safety', style: theme.textTheme.titleMedium),
                Text(
                  'Staff workspace',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (compactActions)
            IconButton(
              tooltip: 'Settings',
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined),
            )
          else
            TextButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined, size: 19),
              label: const Text('Settings'),
            ),
          PopupMenuButton<_AccountAction>(
            tooltip: email.isEmpty ? 'Account' : email,
            onSelected: (action) {
              if (action == _AccountAction.signOut) {
                Supabase.instance.client.auth.signOut();
              } else {
                _openSettings();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AccountAction.profile,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline_rounded),
                  title: Text('My account'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _AccountAction.signOut,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Sign out'),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: scheme.onPrimaryContainer,
                      size: 19,
                    ),
                  ),
                  if (!compactActions) ...[
                    const SizedBox(width: 8),
                    const Text('Account'),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1120;
          return Row(
            children: [
              if (desktop)
                SizedBox(
                  width: 220,
                  child: _StaffSidebar(
                    onOverview: _jumpToOverview,
                    onReports: _jumpToReports,
                    onSettings: _openSettings,
                    activeReports: _navReports,
                  ),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1150),
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        controller: _pageScroll,
                        padding: EdgeInsets.fromLTRB(
                          desktop ? 32 : 18,
                          28,
                          desktop ? 32 : 18,
                          52,
                        ),
                        children: [
                          _DashboardHero(total: _loading ? null : total),
                          const SizedBox(height: 26),
                          _SectionHeading(
                            title: 'At a glance',
                            subtitle: 'Report status across the campus',
                          ),
                          const SizedBox(height: 16),
                          _SummaryRow(
                            counts: _counts,
                            selected: _filter,
                            onTap: _setFilter,
                          ),
                          const SizedBox(height: 30),
                          Card(
                            key: _reportsKey,
                            child: Padding(
                              padding: const EdgeInsets.all(23),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Incident reports',
                                          style: theme.textTheme.titleLarge,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Refresh reports',
                                        onPressed: _loading ? null : _load,
                                        icon: const Icon(Icons.refresh_rounded),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    'Search and review the currently loaded reports.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextField(
                                    key: const Key('admin-report-search'),
                                    onChanged: (value) =>
                                        setState(() => _search = value),
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.search_rounded),
                                      hintText: 'Search category, description or report ID',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('All'),
                                        selected: _filter == null,
                                        onSelected: (_) => _setFilter(null),
                                      ),
                                      for (final status in ReportStatus.values)
                                        ChoiceChip(
                                          label: Text(status.label),
                                          selected: _filter == status,
                                          onSelected: (_) => _setFilter(status),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._buildBody(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [
        _ReportMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load reports',
          message: _error!,
          action: FilledButton(onPressed: _load, child: const Text('Retry')),
        ),
      ];
    }
    final query = _search.trim().toLowerCase();
    final visible = query.isEmpty
        ? _reports
        : _reports
              .where(
                (report) =>
                    report.category.label.toLowerCase().contains(query) ||
                    report.description.toLowerCase().contains(query) ||
                    report.id.toLowerCase().contains(query),
              )
              .toList(growable: false);
    if (visible.isEmpty) {
      return [
        _ReportMessage(
          icon: Icons.inbox_outlined,
          title: query.isNotEmpty
              ? 'No matches found'
              : 'No reports to display',
          message: query.isNotEmpty
              ? 'Try a different keyword or adjust the status filter.'
              : _filter == null
              ? 'Submitted reports will appear here.'
              : 'No ${_filter!.label.toLowerCase()} reports found.',
        ),
      ];
    }
    return [
      for (final report in visible)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _open(report),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 480;
                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.category.label,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        report.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatDateTime(report.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 47,
                        height: 47,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          report.photoPath == null
                              ? Icons.report_outlined
                              : Icons.photo_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: details),
                      if (!narrow) ...[
                        const SizedBox(width: 12),
                        StatusChip(report.status),
                        const SizedBox(width: 10),
                      ],
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
    ];
  }
}

enum _AccountAction { profile, signOut }

class _StaffSidebar extends StatelessWidget {
  const _StaffSidebar({
    required this.onOverview,
    required this.onReports,
    required this.onSettings,
    required this.activeReports,
  });
  final VoidCallback onOverview;
  final VoidCallback onReports;
  final VoidCallback onSettings;
  final bool activeReports;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 26, 13, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Text(
                'WORKSPACE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            _SideNavItem(
              label: 'Overview',
              icon: Icons.space_dashboard_outlined,
              selected: !activeReports,
              onTap: onOverview,
            ),
            _SideNavItem(
              label: 'Incident reports',
              icon: Icons.assignment_outlined,
              selected: activeReports,
              onTap: onReports,
            ),
            const Spacer(),
            _SideNavItem(
              label: 'Settings',
              icon: Icons.settings_outlined,
              selected: false,
              onTap: onSettings,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'UTS CAMPUS SAFETY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.1,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
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

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.total});
  final int? total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 29),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173966), Color(0xFF2356A2), Color(0xFF3472C8)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OPERATIONS OVERVIEW',
                style: TextStyle(
                  letterSpacing: 1.9,
                  color: Color(0xFFD3E3FC),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 11),
              const Text(
                'Campus incidents',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review incoming reports and keep track of progress.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.45,
                ),
              ),
            ],
          );
          final count = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                total?.toString() ?? '–',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 43,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const Text(
                'Total reports',
                style: TextStyle(color: Color(0xFFD8E8FF)),
              ),
            ],
          );
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: 22), count],
            );
          }
          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 20),
              count,
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.counts,
    required this.selected,
    required this.onTap,
  });
  final Map<ReportStatus, int> counts;
  final ReportStatus? selected;
  final ValueChanged<ReportStatus?> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          for (final status in ReportStatus.values)
            _StatusCard(
              status: status,
              count: counts[status],
              selected: selected == status,
              onTap: () => onTap(selected == status ? null : status),
            ),
        ];
        if (constraints.maxWidth < 730) {
          return Column(
            children: [
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: card,
                ),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final ReportStatus status;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = StatusChip.colorFor(status);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? tone : scheme.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(StatusChip.iconFor(status), color: tone, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count?.toString() ?? '–',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontSize: 29, color: tone),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, size: 18, color: tone),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportMessage extends StatelessWidget {
  const _ReportMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(38),
        child: Column(
          children: [
            Icon(icon, size: 35, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 13),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
