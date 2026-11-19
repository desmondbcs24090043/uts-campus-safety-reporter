import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/incident_report.dart';
import '../../data/models/report_status.dart';
import '../../data/repositories/incident_report_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../widgets/status_chip.dart';

/// Web Admin: full details of one report, its private photo (signed URL)
/// and the status update control.
class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({
    super.key,
    required this.reportId,
    required this.repository,
  });

  final String reportId;
  final IncidentReportRepository repository;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  IncidentReport? _report;
  String? _photoUrl;
  String? _photoError;
  String? _error;
  bool _loading = true;

  ReportStatus? _selected; // status chosen in the UI, not yet saved
  bool _saving = false;

  IncidentReportRepository get _repo => widget.repository;

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
      final report = await _repo.fetchReport(widget.reportId);
      String? url;
      String? photoError;
      try {
        url = await _repo.photoUrl(report.photoPath);
      } on RepositoryException catch (e) {
        photoError = e.message;
      }
      if (!mounted) return;
      setState(() {
        _report = report;
        _selected = report.status;
        _photoUrl = url;
        _photoError = photoError;
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

  Future<void> _saveStatus() async {
    final report = _report!;
    final newStatus = _selected!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change status?'),
        content: Text(
            'Change this report from "${report.status.label}" to "${newStatus.label}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await _repo.updateStatus(report.id, newStatus);
      if (!mounted) return;
      setState(() {
        _report = updated;
        _selected = updated.status;
      });
      messenger.showSnackBar(
          SnackBar(content: Text('Status updated to ${updated.status.label}.')));
    } on RepositoryException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final r = _report!;
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      final photo = _PhotoPanel(url: _photoUrl, error: _photoError, hasPhoto: r.photoPath != null);
      final info = _InfoPanel(
        report: r,
        selected: _selected!,
        saving: _saving,
        onSelect: (s) => setState(() => _selected = s),
        onSave: _selected != r.status ? _saveStatus : null,
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: photo),
                      const SizedBox(width: 16),
                      Expanded(child: info),
                    ],
                  )
                : Column(children: [photo, const SizedBox(height: 16), info]),
          ),
        ),
      );
    });
  }
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel({required this.url, required this.error, required this.hasPhoto});

  final String? url;
  final String? error;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!hasPhoto) {
      child = const _Placeholder(icon: Icons.hide_image_outlined, text: 'No photo attached');
    } else if (url == null) {
      child = _Placeholder(icon: Icons.broken_image_outlined, text: error ?? 'Photo unavailable');
    } else {
      child = Image.network(
        url!,
        fit: BoxFit.contain,
        loadingBuilder: (context, w, progress) => progress == null
            ? w
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, e, s) => const _Placeholder(
            icon: Icons.broken_image_outlined, text: 'Could not load photo'),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(aspectRatio: 4 / 3, child: child),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 48), const SizedBox(height: 8), Text(text)],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.report,
    required this.selected,
    required this.saving,
    required this.onSelect,
    required this.onSave,
  });

  final IncidentReport report;
  final ReportStatus selected;
  final bool saving;
  final ValueChanged<ReportStatus> onSelect;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final coords =
        '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}';
    final mapLink =
        'https://www.openstreetmap.org/?mlat=${report.latitude}&mlon=${report.longitude}#map=18/${report.latitude}/${report.longitude}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(report.category.label, style: t.headlineSmall)),
                StatusChip(report.status),
              ],
            ),
            const SizedBox(height: 16),
            Text('Description', style: t.labelLarge),
            const SizedBox(height: 4),
            SelectableText(report.description, style: t.bodyLarge),
            const Divider(height: 32),
            _row(context, Icons.place_outlined, 'Location', coords,
                copy: coords),
            _row(context, Icons.map_outlined, 'Map link', mapLink, copy: mapLink),
            _row(context, Icons.event_outlined, 'Submitted',
                formatDateTime(report.createdAt)),
            _row(context, Icons.update, 'Last updated',
                formatDateTime(report.updatedAt)),
            _row(context, Icons.tag, 'Report ID', report.id, copy: report.id),
            const Divider(height: 32),
            Text('Update status', style: t.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<ReportStatus>(
              segments: [
                for (final s in ReportStatus.values)
                  ButtonSegment(
                      value: s, label: Text(s.label), icon: Icon(StatusChip.iconFor(s))),
              ],
              selected: {selected},
              onSelectionChanged: saving ? null : (set) => onSelect(set.first),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Save status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value,
      {String? copy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Expanded(child: SelectableText(value)),
          if (copy != null)
            IconButton(
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: copy));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$label copied')));
              },
            ),
        ],
      ),
    );
  }
}
