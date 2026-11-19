import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/incident_report.dart';
import '../../data/models/report_status.dart';
import '../../data/repositories/incident_report_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../widgets/status_chip.dart';
import 'report_detail_page.dart';

/// Web Admin: list of ALL reports (RLS only returns everything to admins),
/// with status counts, a status filter and refresh.
class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key, this.repository});

  /// Injectable for tests; defaults to the real Supabase repository.
  final IncidentReportRepository? repository;

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  late final IncidentReportRepository _repo =
      widget.repository ?? IncidentReportRepository();

  ReportStatus? _filter; // null = all
  bool _loading = true;
  String? _error;
  List<IncidentReport> _reports = const [];
  Map<ReportStatus, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _setFilter(ReportStatus? status) {
    if (_filter == status) return;
    setState(() => _filter = status);
    _load();
  }

  Future<void> _open(IncidentReport report) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReportDetailPage(reportId: report.id, repository: _repo),
    ));
    _load(); // status may have changed
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Reports'),
        actions: [
          if (email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(email)),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryRow(
                    counts: _counts, selected: _filter, onTap: _setFilter),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filter == null,
                      onSelected: (_) => _setFilter(null),
                    ),
                    for (final s in ReportStatus.values)
                      ChoiceChip(
                        label: Text(s.label),
                        selected: _filter == s,
                        onSelected: (_) => _setFilter(s),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._buildBody(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [
        _StateMessage(
          icon: Icons.error_outline,
          text: _error!,
          action: FilledButton(onPressed: _load, child: const Text('Retry')),
        ),
      ];
    }
    if (_reports.isEmpty) {
      return [
        _StateMessage(
          icon: Icons.inbox_outlined,
          text: _filter == null
              ? 'No reports yet.'
              : 'No ${_filter!.label.toLowerCase()} reports.',
        ),
      ];
    }
    return [
      for (final r in _reports)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _open(r),
            leading: CircleAvatar(
              child: Icon(r.photoPath != null
                  ? Icons.photo_camera_outlined
                  : Icons.report_outlined),
            ),
            title: Text(r.category.label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${r.description}\n${formatDateTime(r.createdAt)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: StatusChip(r.status),
          ),
        ),
    ];
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.counts, required this.selected, required this.onTap});

  final Map<ReportStatus, int> counts;
  final ReportStatus? selected;
  final ValueChanged<ReportStatus?> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cards = [
        for (final s in ReportStatus.values)
          _SummaryCard(
            status: s,
            count: counts[s],
            selected: selected == s,
            onTap: () => onTap(selected == s ? null : s),
          ),
      ];
      if (c.maxWidth < 600) {
        return Column(
          children: [
            for (final card in cards)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
          ],
        );
      }
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: cards[i]),
          ],
        ],
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
    final color = StatusChip.colorFor(status);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: selected ? color : Colors.transparent, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(StatusChip.iconFor(status), color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(status.label,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(count?.toString() ?? '-',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
