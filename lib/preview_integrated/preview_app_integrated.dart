import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/reports/domain/report_record.dart';
import '../features/reports/presentation/reports_bloc.dart';
import '../features/reports/presentation/reports_event.dart';
import '../features/reports/presentation/reports_state.dart';
import '../preview/preview_theme.dart';
import '../preview/app_appearance.dart';
import '../preview/report_issue_ui.dart';
import '../preview/profile_settings_ui.dart';
import '../preview/notifications_ui.dart';

// Presentation-only icon mapping. ReportRecord stays API-neutral.
IconData _iconForReport(ReportRecord report) => switch (report.title) {
  'Broken corridor light' => Icons.lightbulb_outline_rounded,
  'Wet floor near stairs' => Icons.warning_amber_rounded,
  'Damaged classroom chair' => Icons.chair_alt_outlined,
  'Loose handrail' => Icons.handyman_outlined,
  'Water leak in washroom' => Icons.water_drop_outlined,
  'Damaged campus bench' => Icons.park_outlined,
  _ => Icons.description_outlined,
};

String _formatReportDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

// Member 2 V2 UI integration: original V1 design with V2 BLoC data.
// This is an independent demo; no Authentication or Supabase integration.
class CampusSafetyIntegratedPreviewApp extends StatelessWidget {
  const CampusSafetyIntegratedPreviewApp({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppAppearance.darkMode,
      builder: (context, dark, _) => MaterialApp(
        title: 'Campus Safety Reporter · Demo',
        debugShowCheckedModeBanner: false,
        theme: buildPreviewTheme(dark: false),
        darkTheme: buildPreviewTheme(dark: true),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: _PreviewShell(onSignOut: onSignOut),
      ),
    );
  }
}

class _PreviewShell extends StatefulWidget {
  const _PreviewShell({this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  State<_PreviewShell> createState() => _PreviewShellState();
}

class _PreviewShellState extends State<_PreviewShell> {
  int _selectedIndex = 0;

  void _openDetails(ReportRecord report) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReportDetailsScreen(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _HomeScreen(
                onReportIssue: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReportIssuePreviewPage(),
                  ),
                ),
                onViewAll: () => setState(() => _selectedIndex = 1),
                onOpenReport: _openDetails,
                onNotifications: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsV2Page(),
                    ),
                  );
                },
              ),
              _MyReportsScreen(onOpenReport: _openDetails),
              ProfileV2Page(onSignOut: widget.onSignOut),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AdaptivePalette.surface,
          border: Border(top: BorderSide(color: AdaptivePalette.border)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationDestination(
                    key: Key('nav-home'),
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    key: Key('nav-reports'),
                    icon: Icon(Icons.description_outlined),
                    selectedIcon: Icon(Icons.description_rounded),
                    label: 'My Reports',
                  ),
                  NavigationDestination(
                    key: Key('nav-profile'),
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.onReportIssue,
    required this.onViewAll,
    required this.onOpenReport,
    required this.onNotifications,
  });

  final VoidCallback onReportIssue;
  final VoidCallback onViewAll;
  final ValueChanged<ReportRecord> onOpenReport;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReportsBloc>().state;
    final records = state is ReportsLoaded ? state.records : <ReportRecord>[];
    final recent = records.take(3).toList();
    int count(ReportStatus status) =>
        records.where((r) => r.status == status).length;

    return SafeArea(
      child: ListView(
        key: const Key('dashboard-list'),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdaptivePalette.heroNavy,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAMPUS SAFETY',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w800,
                        color: AdaptivePalette.muted,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Reporter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AdaptivePalette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const _DemoPill(),
              const SizedBox(width: 7),
              IconButton(
                key: const Key('notifications-button'),
                tooltip: 'Notifications',
                onPressed: onNotifications,
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: AdaptivePalette.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 29),
          Text(
            'Hello, Student 👋',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 9),
          Text(
            'A safer campus starts with us. Check the latest updates or report an issue.',
            style: TextStyle(
              color: AdaptivePalette.muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          _ReportHeroCard(onPressed: onReportIssue),
          const SizedBox(height: 30),
          _SectionHeading(
            title: 'My Reports',
            trailing: 'View all',
            onTrailing: onViewAll,
          ),
          const SizedBox(height: 15),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    key: const Key('dashboard-pending-summary'),
                    count: count(ReportStatus.pending),
                    title: 'Pending',
                    icon: Icons.schedule_rounded,
                    background: AdaptivePalette.pendingBg,
                    foreground: AdaptivePalette.pending,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    count: count(ReportStatus.inProgress),
                    title: 'In Progress',
                    icon: Icons.autorenew_rounded,
                    background: AdaptivePalette.progressBg,
                    foreground: AdaptivePalette.progress,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    count: count(ReportStatus.resolved),
                    title: 'Resolved',
                    icon: Icons.check_circle_outline_rounded,
                    background: AdaptivePalette.resolvedBg,
                    foreground: AdaptivePalette.resolved,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 31),
          _SectionHeading(
            title: 'Recent Reports',
            trailing: 'View all',
            onTrailing: onViewAll,
          ),
          const SizedBox(height: 14),
          if (state is ReportsInitial || state is ReportsLoading)
            const _PreviewMessageState(
              title: 'Loading reports',
              description: 'Fetching demonstration reports...',
              showProgress: true,
            )
          else if (state is ReportsFailure) ...[
            _PreviewMessageState(
              title: 'Unable to load reports',
              description: state.message,
              icon: Icons.wifi_off_rounded,
            ),
            TextButton(
              onPressed: () =>
                  context.read<ReportsBloc>().add(const ReportsRequested()),
              child: const Text('Retry'),
            ),
          ] else if (records.isEmpty)
            const _PreviewMessageState(
              title: 'No reports available',
              description: 'There are no demonstration reports to show.',
              icon: Icons.inbox_outlined,
            )
          else
            ...recent.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _ReportCard(
                  report: report,
                  onTap: () => onOpenReport(report),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const _DemoNotice(),
        ],
      ),
    );
  }
}

class _ReportHeroCard extends StatelessWidget {
  const _ReportHeroCard({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('report-issue-cta'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AdaptivePalette.heroNavy, Color(0xFF3271CB)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(21, 26, 19, 26),
            child: Row(
              children: [
                Container(
                  width: 53,
                  height: 53,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report an Issue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Submit an issue with photos and location details.',
                        style: TextStyle(
                          color: Color(0xFFE3EDFF),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.count,
    required this.title,
    required this.icon,
    required this.background,
    required this.foreground,
  });
  final int count;
  final String title;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 115),
      padding: const EdgeInsets.fromLTRB(13, 13, 7, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const Spacer(),
          Text(
            '$count',
            style: TextStyle(
              color: foreground,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.trailing,
    required this.onTrailing,
  });
  final String title;
  final String trailing;
  final VoidCallback onTrailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(
          onPressed: onTrailing,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailing,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyReportsScreen extends StatefulWidget {
  const _MyReportsScreen({required this.onOpenReport});
  final ValueChanged<ReportRecord> onOpenReport;

  @override
  State<_MyReportsScreen> createState() => _MyReportsScreenState();
}

// V2 My Reports: filter/search/refresh are now driven by ReportsBloc.
class _MyReportsScreenState extends State<_MyReportsScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refreshSearchDecoration);
  }

  void _refreshSearchDecoration() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_refreshSearchDecoration);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReportsBloc>().state;
    final loaded = state is ReportsLoaded ? state : null;
    final filtered = loaded?.visibleRecords ?? <ReportRecord>[];
    final filter = loaded?.statusFilter;
    return SafeArea(
      child: ListView(
        key: const Key('my-reports-list'),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MY ACTIVITY',
                  style: TextStyle(
                    letterSpacing: 1.7,
                    fontWeight: FontWeight.w800,
                    color: AdaptivePalette.muted,
                    fontSize: 10,
                  ),
                ),
              ),
              const _DemoPill(),
            ],
          ),
          const SizedBox(height: 13),
          Text('My Reports', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 9),
          Text(
            'Find your submitted reports and follow their status.',
            style: TextStyle(color: AdaptivePalette.muted, fontSize: 13.5),
          ),
          const SizedBox(height: 22),
          TextField(
            key: const Key('reports-search'),
            controller: _controller,
            onChanged: (query) =>
                context.read<ReportsBloc>().add(ReportsSearchChanged(query)),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AdaptivePalette.muted,
              ),
              hintText: 'Search by report ID or issue',
              hintMaxLines: 2,
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _controller.clear();
                        context.read<ReportsBloc>().add(
                          const ReportsSearchChanged(''),
                        );
                      },
                      icon: const Icon(Icons.clear_rounded, size: 20),
                    ),
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: filter == null,
                onPressed: () => context.read<ReportsBloc>().add(
                  const ReportsStatusFilterChanged(null),
                ),
                key: const Key('filter-all'),
              ),
              _FilterChip(
                label: 'Pending',
                selected: filter == ReportStatus.pending,
                onPressed: () => context.read<ReportsBloc>().add(
                  const ReportsStatusFilterChanged(ReportStatus.pending),
                ),
                key: const Key('filter-pending'),
              ),
              _FilterChip(
                label: 'In Progress',
                selected: filter == ReportStatus.inProgress,
                onPressed: () => context.read<ReportsBloc>().add(
                  const ReportsStatusFilterChanged(ReportStatus.inProgress),
                ),
                key: const Key('filter-progress'),
              ),
              _FilterChip(
                label: 'Resolved',
                selected: filter == ReportStatus.resolved,
                onPressed: () => context.read<ReportsBloc>().add(
                  const ReportsStatusFilterChanged(ReportStatus.resolved),
                ),
                key: const Key('filter-resolved'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'All activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (loaded != null)
                Text(
                  '${filtered.length} reports',
                  style: TextStyle(
                    color: AdaptivePalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              IconButton(
                key: const Key('reload-reports'),
                tooltip: 'Reload reports',
                onPressed: () {
                  // Reload clears BLoC filters and the visible search input together.
                  _controller.clear();
                  context.read<ReportsBloc>().add(const ReportsRequested());
                },
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AdaptivePalette.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (state is ReportsInitial || state is ReportsLoading)
            const _PreviewMessageState(
              title: 'Loading reports',
              description: 'Fetching demonstration reports...',
              showProgress: true,
            )
          else if (state is ReportsFailure) ...[
            _PreviewMessageState(
              title: 'Unable to load reports',
              description: state.message,
              icon: Icons.wifi_off_rounded,
            ),
            TextButton(
              onPressed: () {
                _controller.clear();
                context.read<ReportsBloc>().add(const ReportsRequested());
              },
              child: const Text('Retry'),
            ),
          ] else if (filtered.isEmpty)
            const _EmptyResults()
          else
            ...filtered.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _ReportCard(
                  report: report,
                  onTap: () => widget.onOpenReport(report),
                ),
              ),
            ),
          const SizedBox(height: 17),
          const _DemoNotice(),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onPressed(),
      showCheckmark: false,
      side: BorderSide(
        color: selected ? AdaptivePalette.navy : AdaptivePalette.border,
      ),
      backgroundColor: AdaptivePalette.surface,
      selectedColor: AdaptivePalette.paleBlue,
      labelStyle: TextStyle(
        color: selected ? AdaptivePalette.navy : AdaptivePalette.muted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
    );
  }
}

class _PreviewMessageState extends StatelessWidget {
  const _PreviewMessageState({
    required this.title,
    required this.description,
    this.icon = Icons.info_outline_rounded,
    this.showProgress = false,
  });
  final String title;
  final String description;
  final IconData icon;
  final bool showProgress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
    decoration: BoxDecoration(
      color: AdaptivePalette.surface,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: AdaptivePalette.border),
    ),
    child: Column(
      children: [
        if (showProgress)
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 3),
          )
        else
          Icon(icon, size: 33, color: AdaptivePalette.muted),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(color: AdaptivePalette.muted, height: 1.45),
        ),
      ],
    ),
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('empty-reports'),
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 18),
      decoration: BoxDecoration(
        color: AdaptivePalette.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AdaptivePalette.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 37,
            color: AdaptivePalette.muted,
          ),
          SizedBox(height: 12),
          Text(
            'No matching reports',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 7),
          Text(
            'Try another keyword or status filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AdaptivePalette.muted),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});
  final ReportRecord report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdaptivePalette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('report-card-${report.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AdaptivePalette.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: AdaptivePalette.paleBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _iconForReport(report),
                  color: AdaptivePalette.navy,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: TextStyle(
                        color: AdaptivePalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.location,
                      style: TextStyle(
                        color: AdaptivePalette.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _StatusBadge(report.status),
                          Text(
                            _formatReportDate(report.createdAt),
                            style: TextStyle(
                              color: AdaptivePalette.muted,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: AdaptivePalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      ReportStatus.pending => (
        AdaptivePalette.pendingBg,
        AdaptivePalette.pending,
      ),
      ReportStatus.inProgress => (
        AdaptivePalette.progressBg,
        AdaptivePalette.progress,
      ),
      ReportStatus.resolved => (
        AdaptivePalette.resolvedBg,
        AdaptivePalette.resolved,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReportDetailsScreen extends StatelessWidget {
  const _ReportDetailsScreen({required this.report});
  final ReportRecord report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Center(child: _DemoPill()),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            key: const Key('report-details'),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AdaptivePalette.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AdaptivePalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AdaptivePalette.paleBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _iconForReport(report),
                            color: AdaptivePalette.navy,
                            size: 27,
                          ),
                        ),
                        const Spacer(),
                        _StatusBadge(report.status),
                      ],
                    ),
                    const SizedBox(height: 21),
                    Text(
                      report.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      report.id,
                      style: TextStyle(
                        color: AdaptivePalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Divider(color: AdaptivePalette.border, height: 1),
                    const SizedBox(height: 20),
                    _InfoLine(
                      icon: Icons.category_outlined,
                      title: 'Category',
                      value: report.category,
                    ),
                    const SizedBox(height: 17),
                    _InfoLine(
                      icon: Icons.place_outlined,
                      title: 'Location',
                      value: report.location,
                    ),
                    const SizedBox(height: 17),
                    _InfoLine(
                      icon: Icons.calendar_month_outlined,
                      title: 'Date submitted',
                      value: _formatReportDate(report.createdAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _DetailSection(
                heading: 'Description',
                child: Text(
                  report.description,
                  style: TextStyle(
                    color: AdaptivePalette.ink,
                    height: 1.55,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _DetailSection(
                heading: 'Report progress',
                child: _StatusTimeline(status: report.status),
              ),
              const SizedBox(height: 22),
              const _DemoNotice(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 19, color: AdaptivePalette.blue),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: AdaptivePalette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AdaptivePalette.ink,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.heading, required this.child});
  final String heading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AdaptivePalette.surface,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: AdaptivePalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 17),
        child,
      ],
    ),
  );
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    const statuses = [
      ReportStatus.pending,
      ReportStatus.inProgress,
      ReportStatus.resolved,
    ];
    final activeStep = statuses.indexOf(status);
    return Column(
      children: [
        for (var i = 0; i < statuses.length; i++) ...[
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: i <= activeStep
                      ? AdaptivePalette.heroNavy
                      : AdaptivePalette.paleBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  i < activeStep
                      ? Icons.check_rounded
                      : (i == activeStep
                            ? Icons.circle
                            : Icons.circle_outlined),
                  color: i <= activeStep ? Colors.white : AdaptivePalette.muted,
                  size: i == activeStep ? 10 : 14,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  statuses[i].label,
                  style: TextStyle(
                    fontWeight: i == activeStep
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: i <= activeStep
                        ? AdaptivePalette.ink
                        : AdaptivePalette.muted,
                  ),
                ),
              ),
              if (i == activeStep)
                Text(
                  'Current',
                  style: TextStyle(
                    color: AdaptivePalette.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (i < statuses.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 11, top: 3, bottom: 3),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 2,
                  height: 22,
                  color: i < activeStep
                      ? AdaptivePalette.navy
                      : AdaptivePalette.border,
                ),
              ),
            ),
        ],
        const SizedBox(height: 13),
        Text(
          'Illustrative status progression only. No real status history is stored in this preview.',
          style: TextStyle(
            color: AdaptivePalette.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _DemoPill extends StatelessWidget {
  const _DemoPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AdaptivePalette.paleBlue,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      'DEMO',
      style: TextStyle(
        color: AdaptivePalette.navy,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
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
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Demonstration only. Reports, locations, dates and statuses are fictional; Supabase is not connected.',
          style: TextStyle(
            color: AdaptivePalette.muted,
            fontSize: 11.5,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}
