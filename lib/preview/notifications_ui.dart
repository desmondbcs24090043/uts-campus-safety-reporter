import 'package:flutter/material.dart';

import 'preview_theme.dart';

/// Presentation-only notification kinds. No push/local notification channel is
/// configured by this page.
enum CampusNotificationKind { received, inProgress, resolved }

/// UI contract that the notification owner can populate from a real service.
class CampusNotificationRecord {
  const CampusNotificationRecord({
    required this.id,
    required this.title,
    required this.message,
    required this.dateLabel,
    required this.kind,
    required this.reportId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String dateLabel;
  final CampusNotificationKind kind;
  final String reportId;
  final bool isRead;
}

/// All records are fictional and only match IDs used by DemoReportsRepository.
const sampleCampusNotifications = <CampusNotificationRecord>[
  CampusNotificationRecord(
    id: 'sample-received',
    title: 'Report received',
    message: 'Your report about a corridor light has been recorded.',
    dateLabel: '10 Nov 2026',
    kind: CampusNotificationKind.received,
    reportId: 'CSR-2026-001',
    isRead: true,
  ),
  CampusNotificationRecord(
    id: 'sample-progress',
    title: 'Report in progress',
    message: 'The wet floor report is now marked as In Progress.',
    dateLabel: '9 Nov 2026',
    kind: CampusNotificationKind.inProgress,
    reportId: 'CSR-2026-002',
  ),
  CampusNotificationRecord(
    id: 'sample-resolved',
    title: 'Report resolved',
    message: 'The loose handrail report is now marked as Resolved.',
    dateLabel: '6 Nov 2026',
    kind: CampusNotificationKind.resolved,
    reportId: 'CSR-2026-004',
  ),
];

/// Reusable UI page. For preview it shows sample records; the notification owner
/// can later pass live records and wire read state to a real persistence layer.
/// Mark-as-read is currently local to this screen and is NOT saved or delivered
/// to a server. No device alerts are generated.
class NotificationsV2Page extends StatefulWidget {
  const NotificationsV2Page({
    super.key,
    this.notifications = sampleCampusNotifications,
    this.previewMode = true,
  });

  final List<CampusNotificationRecord> notifications;
  final bool previewMode;

  @override
  State<NotificationsV2Page> createState() => _NotificationsV2PageState();
}

class _NotificationsV2PageState extends State<NotificationsV2Page> {
  bool _unreadOnly = false;
  final Set<String> _readInPreview = <String>{};

  bool _isRead(CampusNotificationRecord record) =>
      record.isRead || _readInPreview.contains(record.id);

  @override
  Widget build(BuildContext context) {
    final unread = widget.notifications.where((item) => !_isRead(item)).length;
    final visible = widget.notifications
        .where((item) => !_unreadOnly || !_isRead(item))
        .toList(growable: false);

    return Scaffold(
      key: const Key('notifications-v2-page'),
      backgroundColor: AdaptivePalette.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        titleTextStyle: TextStyle(
          fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
          color: AdaptivePalette.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              key: const Key('notifications-list'),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 35),
              children: [
                if (widget.previewMode) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _DemoLabel(),
                  ),
                  const SizedBox(height: 15),
                ],
                Text(
                  'Stay updated on your reports.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AdaptivePalette.muted,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Recent activity',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AdaptivePalette.ink,
                        ),
                      ),
                    ),
                    if (unread > 0)
                      TextButton(
                        key: const Key('notifications-mark-all-read'),
                        onPressed: () => setState(() {
                          _readInPreview.addAll(
                            widget.notifications.map((item) => item.id),
                          );
                        }),
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 9,
                  runSpacing: 8,
                  children: [
                    _FilterPill(
                      itemKey: 'notifications-all-filter',
                      label: 'All (${widget.notifications.length})',
                      selected: !_unreadOnly,
                      onTap: () => setState(() => _unreadOnly = false),
                    ),
                    _FilterPill(
                      itemKey: 'notifications-unread-filter',
                      label: 'Unread ($unread)',
                      selected: _unreadOnly,
                      onTap: () => setState(() => _unreadOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: 21),
                if (visible.isEmpty)
                  _EmptyNotifications(unreadFilter: _unreadOnly)
                else
                  ...visible.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NotificationTile(
                        item: item,
                        isRead: _isRead(item),
                        onTap: () => _openNotification(item),
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

  void _openNotification(CampusNotificationRecord item) {
    setState(() => _readInPreview.add(item.id));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AdaptivePalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 8, 25, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: AdaptivePalette.navy,
                  size: 28,
                ),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 9),
                Text(
                  item.message,
                  style: TextStyle(color: AdaptivePalette.ink, height: 1.5),
                ),
                const SizedBox(height: 14),
                Text(
                  '${item.reportId}  ·  ${item.dateLabel}',
                  style: TextStyle(color: AdaptivePalette.muted, fontSize: 12),
                ),
                if (widget.previewMode) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Sample notification',
                    style: TextStyle(
                      color: AdaptivePalette.muted,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  key: const Key('notifications-detail-close'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.isRead,
    required this.onTap,
  });

  final CampusNotificationRecord item;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, background, foreground) = switch (item.kind) {
      CampusNotificationKind.received => (
        Icons.assignment_turned_in_outlined,
        AdaptivePalette.paleBlue,
        AdaptivePalette.navy,
      ),
      CampusNotificationKind.inProgress => (
        Icons.autorenew_rounded,
        AdaptivePalette.progressBg,
        AdaptivePalette.progress,
      ),
      CampusNotificationKind.resolved => (
        Icons.check_circle_outline_rounded,
        AdaptivePalette.resolvedBg,
        AdaptivePalette.resolved,
      ),
    };

    return Material(
      color: AdaptivePalette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: Key('notifications-item-${item.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 17, 16, 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AdaptivePalette.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: foreground, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w700
                                  : FontWeight.w800,
                              color: AdaptivePalette.ink,
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 9),
                          Container(
                            key: Key('notifications-unread-dot-${item.id}'),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AdaptivePalette.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.message,
                      style: TextStyle(
                        color: AdaptivePalette.muted,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            item.reportId,
                            style: TextStyle(
                              color: AdaptivePalette.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            item.dateLabel,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.itemKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String itemKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    key: Key(itemKey),
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    backgroundColor: AdaptivePalette.surface,
    selectedColor: AdaptivePalette.paleBlue,
    side: BorderSide(
      color: selected ? AdaptivePalette.navy : AdaptivePalette.border,
    ),
    labelStyle: TextStyle(
      color: selected ? AdaptivePalette.navy : AdaptivePalette.muted,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.unreadFilter});

  final bool unreadFilter;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('notifications-empty-state'),
    padding: const EdgeInsets.fromLTRB(25, 36, 25, 36),
    decoration: BoxDecoration(
      color: AdaptivePalette.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AdaptivePalette.border),
    ),
    child: Column(
      children: [
        Icon(
          Icons.notifications_none_rounded,
          color: AdaptivePalette.muted,
          size: 39,
        ),
        const SizedBox(height: 15),
        Text(
          unreadFilter ? "You're all caught up" : 'No notifications yet',
          style: TextStyle(
            color: AdaptivePalette.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          unreadFilter
              ? 'You have no unread notifications.'
              : 'Updates about your reports will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AdaptivePalette.muted,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _DemoLabel extends StatelessWidget {
  const _DemoLabel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AdaptivePalette.paleBlue,
      borderRadius: BorderRadius.circular(10),
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
