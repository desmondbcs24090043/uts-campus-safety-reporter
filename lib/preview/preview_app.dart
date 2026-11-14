import 'package:flutter/material.dart';
import 'demo_data.dart';
import 'preview_theme.dart';

// MEMBER 2 - independent UI preview only. All reports are fictional.
// Do not use this entry point for authentication, upload, or production data.
class CampusSafetyPreviewApp extends StatelessWidget {
  const CampusSafetyPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Safety Reporter · Demo',
      debugShowCheckedModeBanner: false,
      theme: buildPreviewTheme(),
      home: const _PreviewShell(),
    );
  }
}

class _PreviewShell extends StatefulWidget {
  const _PreviewShell();

  @override
  State<_PreviewShell> createState() => _PreviewShellState();
}

class _PreviewShellState extends State<_PreviewShell> {
  int _selectedIndex = 0;

  void _showNotReady(String feature, String owner) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 10, 26, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.construction_rounded, size: 30, color: PreviewColours.blue),
              const SizedBox(height: 14),
              Text('$feature is not connected yet', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text('This is a Member 2 UI preview with demonstration data. $owner will integrate this feature later.',
                style: const TextStyle(color: PreviewColours.muted, height: 1.5)),
              const SizedBox(height: 18),
              FilledButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Got it')),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(DemoReport report) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _ReportDetailsScreen(report: report),
    ));
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
                onReportIssue: () => _showNotReady('Report an Issue', 'Member 3'),
                onViewAll: () => setState(() => _selectedIndex = 1),
                onOpenReport: _openDetails,
                onNotifications: () => _showNotReady('Notifications', 'The notifications team'),
              ),
              _MyReportsScreen(onOpenReport: _openDetails),
              _ProfileScreen(onAuth: () => _showNotReady('Profile and Authentication', 'Member 1')),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PreviewColours.border)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationDestination(key: Key('nav-home'), icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
                  NavigationDestination(key: Key('nav-reports'), icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description_rounded), label: 'My Reports'),
                  NavigationDestination(key: Key('nav-profile'), icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
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
  final ValueChanged<DemoReport> onOpenReport;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final recent = demoReports.take(3).toList();
    int count(ReportStatus status) => demoReports.where((r) => r.status == status).length;

    return SafeArea(
      child: ListView(
        key: const Key('dashboard-list'),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: PreviewColours.navy, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CAMPUS SAFETY', style: TextStyle(fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800, color: PreviewColours.muted)),
                  SizedBox(height: 3),
                  Text('Reporter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PreviewColours.ink)),
                ]),
              ),
              const _DemoPill(),
              const SizedBox(width: 7),
              IconButton(
                key: const Key('notifications-button'),
                tooltip: 'Notifications (coming soon)',
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_none_rounded, color: PreviewColours.navy),
              ),
            ],
          ),
          const SizedBox(height: 29),
          Text('Hello, Student 👋', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 9),
          const Text('A safer campus starts with us. Check the latest updates or report an issue.',
            style: TextStyle(color: PreviewColours.muted, fontSize: 14, height: 1.5)),
          const SizedBox(height: 26),
          _ReportHeroCard(onPressed: onReportIssue),
          const SizedBox(height: 30),
          _SectionHeading(title: 'My Reports', trailing: 'View all', onTrailing: onViewAll),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _StatTile(count: count(ReportStatus.pending), title: 'Pending', icon: Icons.schedule_rounded, background: PreviewColours.pendingBg, foreground: PreviewColours.pending)),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(count: count(ReportStatus.inProgress), title: 'In Progress', icon: Icons.autorenew_rounded, background: PreviewColours.progressBg, foreground: PreviewColours.progress)),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(count: count(ReportStatus.resolved), title: 'Resolved', icon: Icons.check_circle_outline_rounded, background: PreviewColours.resolvedBg, foreground: PreviewColours.resolved)),
          ]),
          const SizedBox(height: 31),
          _SectionHeading(title: 'Recent Reports', trailing: 'View all', onTrailing: onViewAll),
          const SizedBox(height: 14),
          ...recent.map((report) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _ReportCard(report: report, onTap: () => onOpenReport(report)),
          )),
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PreviewColours.navy, Color(0xFF3271CB)],
            ),
            boxShadow: [BoxShadow(color: PreviewColours.navy.withValues(alpha: .18), offset: const Offset(0, 10), blurRadius: 22)],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(21, 26, 19, 26),
            child: Row(children: [
              Container(
                width: 53, height: 53,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(17)),
                child: const Icon(Icons.campaign_outlined, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Report an Issue', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                SizedBox(height: 7),
                Text('Submit an issue with photos and location details.', style: TextStyle(color: Color(0xFFE3EDFF), fontSize: 12, height: 1.45)),
              ])),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 17),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.count, required this.title, required this.icon, required this.background, required this.foreground});
  final int count;
  final String title;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 115,
      padding: const EdgeInsets.fromLTRB(13, 13, 7, 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(19)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: foreground, size: 20),
        const Spacer(),
        Text('$count', style: TextStyle(color: foreground, fontSize: 27, fontWeight: FontWeight.w800, height: 1)),
        const SizedBox(height: 6),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: foreground, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.trailing, required this.onTrailing});
  final String title;
  final String trailing;
  final VoidCallback onTrailing;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
      TextButton(onPressed: onTrailing, child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(trailing, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_forward_rounded, size: 16),
      ])),
    ]);
  }
}

class _MyReportsScreen extends StatefulWidget {
  const _MyReportsScreen({required this.onOpenReport});
  final ValueChanged<DemoReport> onOpenReport;

  @override
  State<_MyReportsScreen> createState() => _MyReportsScreenState();
}

enum _ReportViewMode { populated, loading, empty, error }

class _MyReportsScreenState extends State<_MyReportsScreen> {
  _ReportViewMode _viewMode = _ReportViewMode.populated;
  final TextEditingController _controller = TextEditingController();
  ReportStatus? _filter;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  List<DemoReport> get _filteredReports {
    final query = _controller.text.trim().toLowerCase();
    return demoReports.where((report) {
      final matchesStatus = _filter == null || report.status == _filter;
      final matchesQuery = query.isEmpty || '${report.id} ${report.title} ${report.category} ${report.location}'.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports;
    return SafeArea(child: ListView(
      key: const Key('my-reports-list'),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      children: [
        Row(children: [
          const Expanded(child: Text('MY ACTIVITY', style: TextStyle(letterSpacing: 1.7, fontWeight: FontWeight.w800, color: PreviewColours.muted, fontSize: 10))),
          const _DemoPill(),
        ]),
        const SizedBox(height: 13),
        Text('My Reports', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 9),
        const Text('Find your submitted reports and follow their status.', style: TextStyle(color: PreviewColours.muted, fontSize: 13.5)),
        const SizedBox(height: 22),
        TextField(
          key: const Key('reports-search'),
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, color: PreviewColours.muted),
            hintText: 'Search by report ID or issue',
            suffixIcon: _controller.text.isEmpty ? null : IconButton(
              tooltip: 'Clear search',
              onPressed: _controller.clear,
              icon: const Icon(Icons.clear_rounded, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _FilterChip(label: 'All', selected: _filter == null, onPressed: () => setState(() => _filter = null), key: const Key('filter-all')),
            const SizedBox(width: 8),
            _FilterChip(label: 'Pending', selected: _filter == ReportStatus.pending, onPressed: () => setState(() => _filter = ReportStatus.pending), key: const Key('filter-pending')),
            const SizedBox(width: 8),
            _FilterChip(label: 'In Progress', selected: _filter == ReportStatus.inProgress, onPressed: () => setState(() => _filter = ReportStatus.inProgress), key: const Key('filter-progress')),
            const SizedBox(width: 8),
            _FilterChip(label: 'Resolved', selected: _filter == ReportStatus.resolved, onPressed: () => setState(() => _filter = ReportStatus.resolved), key: const Key('filter-resolved')),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Text('All activity', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (_viewMode == _ReportViewMode.populated)
            Text('${filtered.length} reports', style: const TextStyle(color: PreviewColours.muted, fontSize: 12, fontWeight: FontWeight.w600)),
          PopupMenuButton<_ReportViewMode>(
            key: const Key('preview-states-menu'),
            tooltip: 'Preview loading, empty and error UI states',
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: PreviewColours.muted),
            onSelected: (mode) => setState(() => _viewMode = mode),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _ReportViewMode.populated, child: Text('Show demo reports')),
              PopupMenuItem(value: _ReportViewMode.loading, child: Text('Preview loading state')),
              PopupMenuItem(value: _ReportViewMode.empty, child: Text('Preview empty state')),
              PopupMenuItem(value: _ReportViewMode.error, child: Text('Preview error state')),
            ],
          ),
        ]),
        const SizedBox(height: 13),
        if (_viewMode == _ReportViewMode.loading)
          const _PreviewMessageState(
            title: 'Loading reports',
            description: 'This shows the future loading state of the live API.',
            showProgress: true,
          )
        else if (_viewMode == _ReportViewMode.empty)
          const _EmptyResults()
        else if (_viewMode == _ReportViewMode.error)
          const _PreviewMessageState(
            title: 'Unable to load reports',
            description: 'A network or API error message will appear here after backend integration.',
            icon: Icons.wifi_off_rounded,
          )
        else if (filtered.isEmpty)
          const _EmptyResults()
        else
          ...filtered.map((report) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _ReportCard(report: report, onTap: () => widget.onOpenReport(report)),
          )),
        const SizedBox(height: 17),
        const _DemoNotice(),
      ],
    ));
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({super.key, required this.label, required this.selected, required this.onPressed});
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
      side: BorderSide(color: selected ? PreviewColours.navy : PreviewColours.border),
      backgroundColor: Colors.white,
      selectedColor: PreviewColours.paleBlue,
      labelStyle: TextStyle(color: selected ? PreviewColours.navy : PreviewColours.muted, fontWeight: FontWeight.w700, fontSize: 12),
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
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21), border: Border.all(color: PreviewColours.border)),
    child: Column(children: [
      if (showProgress)
        const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3))
      else
        Icon(icon, size: 33, color: PreviewColours.muted),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      Text(description, textAlign: TextAlign.center, style: const TextStyle(color: PreviewColours.muted, height: 1.45)),
    ]),
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('empty-reports'),
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21), border: Border.all(color: PreviewColours.border)),
      child: const Column(children: [
        Icon(Icons.search_off_rounded, size: 37, color: PreviewColours.muted),
        SizedBox(height: 12),
        Text('No matching reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        SizedBox(height: 7),
        Text('Try another keyword or status filter.', textAlign: TextAlign.center, style: TextStyle(color: PreviewColours.muted)),
      ]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});
  final DemoReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('report-card-${report.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: PreviewColours.border)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 49, height: 49,
              decoration: BoxDecoration(color: PreviewColours.paleBlue, borderRadius: BorderRadius.circular(15)),
              child: Icon(report.icon, color: PreviewColours.navy, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(report.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: PreviewColours.ink, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(report.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: PreviewColours.muted, fontSize: 11.5)),
              const SizedBox(height: 10),
              Row(children: [
                _StatusBadge(report.status),
                const Spacer(),
                Text(formatDemoDate(report.createdAt), style: const TextStyle(color: PreviewColours.muted, fontSize: 10.5)),
              ]),
            ])),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 19, color: PreviewColours.muted),
          ]),
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
      ReportStatus.pending => (PreviewColours.pendingBg, PreviewColours.pending),
      ReportStatus.inProgress => (PreviewColours.progressBg, PreviewColours.progress),
      ReportStatus.resolved => (PreviewColours.resolvedBg, PreviewColours.resolved),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Text(status.label, style: TextStyle(color: foreground, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _ReportDetailsScreen extends StatelessWidget {
  const _ReportDetailsScreen({required this.report});
  final DemoReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: const [Padding(padding: EdgeInsets.only(right: 18), child: Center(child: _DemoPill()))],
      ),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ListView(
          key: const Key('report-details'),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PreviewColours.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: PreviewColours.paleBlue, borderRadius: BorderRadius.circular(16)),
                    child: Icon(report.icon, color: PreviewColours.navy, size: 27),
                  ),
                  const Spacer(),
                  _StatusBadge(report.status),
                ]),
                const SizedBox(height: 21),
                Text(report.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 9),
                Text(report.id, style: const TextStyle(color: PreviewColours.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .4)),
                const SizedBox(height: 22),
                const Divider(color: PreviewColours.border, height: 1),
                const SizedBox(height: 20),
                _InfoLine(icon: Icons.category_outlined, title: 'Category', value: report.category),
                const SizedBox(height: 17),
                _InfoLine(icon: Icons.place_outlined, title: 'Location', value: report.location),
                const SizedBox(height: 17),
                _InfoLine(icon: Icons.calendar_month_outlined, title: 'Date submitted', value: formatDemoDate(report.createdAt)),
              ]),
            ),
            const SizedBox(height: 22),
            _DetailSection(
              heading: 'Description',
              child: Text(report.description, style: const TextStyle(color: PreviewColours.ink, height: 1.55, fontSize: 13.5)),
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
      )),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 19, color: PreviewColours.blue),
    const SizedBox(width: 13),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 11, color: PreviewColours.muted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: PreviewColours.ink)),
    ])),
  ]);
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.heading, required this.child});
  final String heading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23), border: Border.all(color: PreviewColours.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(heading, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 17),
      child,
    ]),
  );
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    const statuses = [ReportStatus.pending, ReportStatus.inProgress, ReportStatus.resolved];
    final activeStep = statuses.indexOf(status);
    return Column(children: [
      for (var i = 0; i < statuses.length; i++) ...[
        Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: i <= activeStep ? PreviewColours.navy : PreviewColours.paleBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(i < activeStep ? Icons.check_rounded : (i == activeStep ? Icons.circle : Icons.circle_outlined),
              color: i <= activeStep ? Colors.white : PreviewColours.muted, size: i == activeStep ? 10 : 14),
          ),
          const SizedBox(width: 13),
          Expanded(child: Text(statuses[i].label,
            style: TextStyle(fontWeight: i == activeStep ? FontWeight.w800 : FontWeight.w600,
              color: i <= activeStep ? PreviewColours.ink : PreviewColours.muted))),
          if (i == activeStep)
            const Text('Current', style: TextStyle(color: PreviewColours.blue, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
        if (i < statuses.length - 1)
          Padding(
            padding: const EdgeInsets.only(left: 11, top: 3, bottom: 3),
            child: Align(alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 22, color: i < activeStep ? PreviewColours.navy : PreviewColours.border)),
          ),
      ],
      const SizedBox(height: 13),
      const Text('Illustrative status progression only. No real status history is stored in this preview.',
        style: TextStyle(color: PreviewColours.muted, fontSize: 11, height: 1.4)),
    ]);
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({required this.onAuth});
  final VoidCallback onAuth;

  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(
    padding: const EdgeInsets.fromLTRB(22, 30, 22, 25),
    children: [
      const Align(alignment: Alignment.centerLeft, child: _DemoPill()),
      const SizedBox(height: 16),
      Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 19),
      Container(
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23), border: Border.all(color: PreviewColours.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(radius: 27, backgroundColor: PreviewColours.paleBlue,
            child: Icon(Icons.person_outline_rounded, size: 29, color: PreviewColours.navy)),
          const SizedBox(height: 16),
          const Text('Student account', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Profile data and secure sign-in will be provided by Member 1. This screen does not authenticate a user.',
            style: TextStyle(color: PreviewColours.muted, height: 1.5)),
          const SizedBox(height: 17),
          OutlinedButton.icon(
            key: const Key('profile-placeholder'),
            onPressed: onAuth,
            icon: const Icon(Icons.lock_outline_rounded, size: 18),
            label: const Text('Authentication integration'),
          ),
        ]),
      ),
      const SizedBox(height: 19),
      const _DemoNotice(),
    ],
  ));
}

class _DemoPill extends StatelessWidget {
  const _DemoPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: PreviewColours.paleBlue, borderRadius: BorderRadius.circular(11)),
    child: const Text('DEMO', style: TextStyle(color: PreviewColours.navy, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .8)),
  );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.info_outline_rounded, size: 16, color: PreviewColours.muted),
    const SizedBox(width: 8),
    const Expanded(child: Text('Demonstration only. Reports, locations, dates and statuses are fictional; Supabase is not connected.',
      style: TextStyle(color: PreviewColours.muted, fontSize: 11.5, height: 1.5))),
  ]);
}
