import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/incident_report.dart';
import '../../data/models/report_status.dart';
import '../../data/repositories/incident_report_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../widgets/status_chip.dart';

/// Staff-only report details. Repository rules and write permissions are unchanged.
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
  bool _saving = false;
  ReportStatus? _selected;

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
      String? photoUrl;
      String? photoError;
      if (report.photoPath != null) {
        try {
          photoUrl = await _repo.photoUrl(report.photoPath);
        } on RepositoryException catch (error) {
          photoError = error.message;
        }
      }
      if (!mounted) return;
      setState(() {
        _report = report;
        _selected = report.status;
        _photoUrl = photoUrl;
        _photoError = photoError;
        _loading = false;
      });
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this report. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _saveStatus() async {
    final report = _report;
    final status = _selected;
    if (_saving ||
        report == null ||
        status == null ||
        status == report.status) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change report status?'),
        content: Text(
          'Change this report from "${report.status.label}" to "${status.label}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await _repo.updateStatus(report.id, status);
      if (!mounted) return;
      setState(() {
        _report = updated;
        _selected = updated.status;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Status updated to ${updated.status.label}.')),
      );
    } on RepositoryException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not save status. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 74, title: const Text('Report details')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 14),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final report = _report!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasMedia = report.photoPath != null;
        final wide = hasMedia && constraints.maxWidth >= 920;
        final details = _ReportInfoCard(
          report: report,
          selected: _selected!,
          saving: _saving,
          onSelected: (value) => setState(() => _selected = value),
          onSave: _selected == report.status ? null : _saveStatus,
        );
        final media = hasMedia
            ? _MediaPreview(url: _photoUrl, error: _photoError)
            : const _MediaEmptyNote();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 52),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: hasMedia ? 1180 : 940),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INCIDENT REPORT',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.category.label,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 23),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: media),
                        const SizedBox(width: 18),
                        Expanded(flex: 6, child: details),
                      ],
                    )
                  else ...[
                    details,
                    const SizedBox(height: 16),
                    media,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MediaEmptyNote extends StatelessWidget {
  const _MediaEmptyNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        child: Row(
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No photo attached',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.url, required this.error});
  final String? url;
  final String? error;

  @override
  Widget build(BuildContext context) {
    Widget media;
    if (url == null) {
      media = _MediaPlaceholder(error ?? 'Photo unavailable');
    } else {
      media = Image.network(
        url!,
        fit: BoxFit.contain,
        loadingBuilder: (context, image, progress) => progress == null
            ? image
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stack) =>
            const _MediaPlaceholder('Could not load photo'),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 12),
            child: Text(
              'Attached photo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: media,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 35),
          const SizedBox(height: 10),
          Text(message),
        ],
      ),
    );
  }
}

class _ReportInfoCard extends StatelessWidget {
  const _ReportInfoCard({
    required this.report,
    required this.selected,
    required this.saving,
    required this.onSelected,
    required this.onSave,
  });
  final IncidentReport report;
  final ReportStatus selected;
  final bool saving;
  final ValueChanged<ReportStatus> onSelected;
  final VoidCallback? onSave;

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied')));
  }

  Future<void> _openMap(BuildContext context) async {
    final lat = report.latitude;
    final lon = report.longitude;
    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=18/$lat/$lon',
    );
    try {
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Unable to open map.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Unable to open map.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final coords =
        '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Report information',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                StatusChip(report.status),
              ],
            ),
            const SizedBox(height: 24),
            Text('Description', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SelectableText(
              report.description,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const Divider(height: 38),
            _InfoRow(
              icon: Icons.place_outlined,
              title: 'Location',
              value: coords,
              onCopy: () => _copy(context, 'Location', coords),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(35, 0, 0, 8),
              child: TextButton.icon(
                onPressed: () => _openMap(context),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('View on map'),
              ),
            ),
            _InfoRow(
              icon: Icons.event_outlined,
              title: 'Submitted',
              value: formatDateTime(report.createdAt),
            ),
            _InfoRow(
              icon: Icons.update_outlined,
              title: 'Last updated',
              value: formatDateTime(report.updatedAt),
            ),
            _InfoRow(
              icon: Icons.tag_rounded,
              title: 'Report ID',
              value: report.id,
              onCopy: () => _copy(context, 'Report ID', report.id),
            ),
            const Divider(height: 38),
            Text('Update status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Changes are saved to the shared database.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<ReportStatus>(
                segments: [
                  for (final s in ReportStatus.values)
                    ButtonSegment<ReportStatus>(
                      value: s,
                      label: Text(s.label),
                      icon: Icon(StatusChip.iconFor(s), size: 16),
                    ),
                ],
                selected: {selected},
                onSelectionChanged: saving
                    ? null
                    : (values) => onSelected(values.first),
              ),
            ),
            const SizedBox(height: 17),
            FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save status'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onCopy,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          SizedBox(
            width: 104,
            child: Text(title, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: SelectableText(value, style: theme.textTheme.bodyMedium),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'Copy $title',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded, size: 16),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
