import 'package:flutter/material.dart';

import 'demo_data.dart';
import 'preview_theme.dart';

/// Member 2 UI enhancement: an isolated, interactive DEMO of Campus Reports.
///
/// All entries come from the fictional demo_data.dart fixture. The interactions
/// on this page are ephemeral: they do not read or write Supabase, do not
/// publish a report, and are cleared when this widget is destroyed.
/// IMPORTANT: incident_reports currently has owner-only student SELECT RLS.
/// Never query other students' private incident_reports directly for a feed.
class CampusFeedPreviewPage extends StatefulWidget {
  const CampusFeedPreviewPage({super.key, this.onOpenReport});

  final ValueChanged<DemoReport>? onOpenReport;

  @override
  State<CampusFeedPreviewPage> createState() => _CampusFeedPreviewPageState();
}

class _CampusFeedPreviewPageState extends State<CampusFeedPreviewPage> {
  String _category = 'All';
  final Set<String> _noticed = <String>{};
  // UI-only Helpful reactions, scoped to one report and lost on app restart.
  // These are NOT shared between students and do NOT imply actual like counts.
  final Map<String, Set<String>> _helpfulByReport = <String, Set<String>>{};
  // Fictional UI fixtures. None of these are real campus users or incidents.
  // No identifiers, reactions or comments are written to Supabase.
  final Map<String, List<_DemoComment>> _comments = {
    'CSR-2026-001': [
      _DemoComment(
        id: 'sample-student-1',
        author: 'Alex T. (sample)',
        message: 'I noticed the same issue in this corridor yesterday.',
        createdAt: DateTime(2026, 11, 19, 11, 20),
      ),
      _DemoComment(
        id: 'sample-staff-1',
        author: 'Campus Safety Team (sample)',
        message: 'Thanks for raising this. Our team will review the location.',
        createdAt: DateTime(2026, 11, 19, 12, 5),
        isStaff: true,
      ),
    ],
  };

  List<DemoReport> get _visibleReports {
    final reports = demoReports.where((report) {
      if (_category == 'All') return true;
      if (_category == 'Safety') return report.category == 'Safety Hazard';
      return report.category == _category;
    }).toList();
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  Future<void> _showComments(DemoReport report) async {
    final comments = _comments.putIfAbsent(report.id, () => <_DemoComment>[]);
    final helpful = _helpfulByReport.putIfAbsent(report.id, () => <String>{});
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AdaptivePalette.surface,
      showDragHandle: true,
      builder: (_) => _DemoCommentsSheet(
        reportTitle: report.title,
        comments: List<_DemoComment>.of(comments),
        helpfulCommentIds: Set<String>.of(helpful),
        onToggleHelpful: (id) {
          if (!mounted) return;
          setState(() {
            if (!helpful.add(id)) helpful.remove(id);
          });
        },
        onAdd: (comment) {
          if (!mounted) return;
          setState(() => comments.add(comment));
        },
        onDelete: (id) {
          if (!mounted) return;
          setState(() {
            comments.removeWhere((comment) => comment.id == id && comment.own);
            helpful.remove(id);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = _visibleReports;
    final narrow = MediaQuery.sizeOf(context).width < 370;

    return SafeArea(
      child: ListView(
        key: const Key('campus-feed-scroll'),
        padding: EdgeInsets.fromLTRB(
          narrow ? 15 : 20,
          24,
          narrow ? 15 : 20,
          28,
        ),
        children: [
          Text(
            'Campus reports',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'See what is happening around campus.',
            style: TextStyle(color: AdaptivePalette.muted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AdaptivePalette.deepNavy, AdaptivePalette.heroNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.groups_2_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'A safer campus, together.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Stay informed about reported issues. Only approved reports should appear in the live feed.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AdaptivePalette.paleBlue,
              border: Border.all(color: AdaptivePalette.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AdaptivePalette.navy,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'UI preview · Fictional sample reports. Reactions and comments are local only, not published.',
                    style: TextStyle(
                      color: AdaptivePalette.ink,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Latest reports',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${reports.length} shown',
                style: TextStyle(color: AdaptivePalette.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final label in const [
                  'All',
                  'Safety',
                  'Facilities',
                  'Maintenance',
                ]) ...[
                  ChoiceChip(
                    key: Key('feed-filter-${label.toLowerCase()}'),
                    label: Text(label),
                    selected: _category == label,
                    onSelected: (_) => setState(() => _category = label),
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
          const SizedBox(height: 15),
          if (reports.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
              decoration: BoxDecoration(
                color: AdaptivePalette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AdaptivePalette.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 30,
                    color: AdaptivePalette.muted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No reports in this category',
                    style: TextStyle(color: AdaptivePalette.ink),
                  ),
                ],
              ),
            )
          else
            for (final report in reports) ...[
              _FeedReportCard(
                key: Key('campus-feed-${report.id}'),
                report: report,
                noticed: _noticed.contains(report.id),
                commentCount: _comments[report.id]?.length ?? 0,
                onNoticed: () => setState(() {
                  if (!_noticed.add(report.id)) _noticed.remove(report.id);
                }),
                onComments: () => _showComments(report),
                onOpen: widget.onOpenReport == null
                    ? null
                    : () => widget.onOpenReport!(report),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _FeedReportCard extends StatelessWidget {
  const _FeedReportCard({
    super.key,
    required this.report,
    required this.noticed,
    this.onOpen,
    required this.commentCount,
    required this.onNoticed,
    required this.onComments,
  });

  final DemoReport report;
  final bool noticed;
  final VoidCallback? onOpen;
  final int commentCount;
  final VoidCallback onNoticed;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg) = switch (report.status) {
      ReportStatus.pending => (
        AdaptivePalette.pending,
        AdaptivePalette.pendingBg,
      ),
      ReportStatus.inProgress => (
        AdaptivePalette.progress,
        AdaptivePalette.progressBg,
      ),
      ReportStatus.resolved => (
        AdaptivePalette.resolved,
        AdaptivePalette.resolvedBg,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AdaptivePalette.surface,
        border: Border.all(color: AdaptivePalette.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AdaptivePalette.paleBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(report.icon, color: AdaptivePalette.navy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.category,
                      style: TextStyle(
                        color: AdaptivePalette.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      report.title,
                      style: TextStyle(
                        color: AdaptivePalette.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            report.description,
            style: TextStyle(
              color: AdaptivePalette.ink,
              height: 1.5,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AdaptivePalette.muted,
                size: 15,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  style: TextStyle(color: AdaptivePalette.muted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatDemoDate(report.createdAt),
                style: TextStyle(color: AdaptivePalette.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  report.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'SAMPLE',
                style: TextStyle(
                  color: AdaptivePalette.muted,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          if (onOpen != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('feed-details-${report.id}'),
                onPressed: onOpen,
                child: const Text('View details'),
              ),
            ),
          const SizedBox(height: 13),
          Divider(color: AdaptivePalette.border, height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              TextButton.icon(
                key: Key('noticed-${report.id}'),
                onPressed: onNoticed,
                icon: Icon(
                  noticed
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 18,
                ),
                label: Text(noticed ? 'Noted · 1' : 'I also noticed'),
                style: TextButton.styleFrom(
                  foregroundColor: AdaptivePalette.navy,
                ),
              ),
              TextButton.icon(
                key: Key('comments-${report.id}'),
                onPressed: onComments,
                icon: const Icon(Icons.mode_comment_outlined, size: 18),
                label: Text(
                  'Comments${commentCount == 0 ? '' : ' · $commentCount'}',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AdaptivePalette.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// DEMO-only comment. No email, student ID, Supabase ID or real identity.
class _DemoComment {
  const _DemoComment({
    required this.id,
    required this.author,
    required this.message,
    required this.createdAt,
    this.isStaff = false,
    this.own = false,
  });

  final String id;
  final String author;
  final String message;
  final DateTime createdAt;
  final bool isStaff;
  final bool own;
}

String _commentTime(DateTime value) {
  final hours = value.hour.toString().padLeft(2, '0');
  final minutes = value.minute.toString().padLeft(2, '0');
  return '${formatDemoDate(value)} · $hours:$minutes';
}

class _DemoCommentsSheet extends StatefulWidget {
  const _DemoCommentsSheet({
    required this.reportTitle,
    required this.comments,
    required this.helpfulCommentIds,
    required this.onToggleHelpful,
    required this.onAdd,
    required this.onDelete,
  });

  final String reportTitle;
  final List<_DemoComment> comments;
  final Set<String> helpfulCommentIds;
  final ValueChanged<String> onToggleHelpful;
  final ValueChanged<_DemoComment> onAdd;
  final ValueChanged<String> onDelete;

  @override
  State<_DemoCommentsSheet> createState() => _DemoCommentsSheetState();
}

class _DemoCommentsSheetState extends State<_DemoCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  late final List<_DemoComment> _comments;
  late final Set<String> _helpfulCommentIds;

  @override
  void initState() {
    super.initState();
    _comments = List<_DemoComment>.of(widget.comments);
    _helpfulCommentIds = Set<String>.of(widget.helpfulCommentIds);
  }

  void _toggleHelpful(String id) {
    setState(() {
      if (!_helpfulCommentIds.add(id)) _helpfulCommentIds.remove(id);
    });
    widget.onToggleHelpful(id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty || value.length > 500) return;
    final comment = _DemoComment(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      author: 'You (demo)',
      message: value,
      createdAt: DateTime.now(),
      own: true,
    );
    setState(() => _comments.add(comment));
    widget.onAdd(comment);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  void _delete(_DemoComment comment) {
    if (!comment.own) return;
    setState(() {
      _comments.removeWhere((entry) => entry.id == comment.id);
      _helpfulCommentIds.remove(comment.id);
    });
    widget.onDelete(comment.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        6,
        20,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Comments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${_comments.length}',
                  style: TextStyle(color: AdaptivePalette.muted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.reportTitle,
              style: TextStyle(color: AdaptivePalette.muted),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo only · Authors, comments and Helpful reactions are fictional or local.',
              style: TextStyle(color: AdaptivePalette.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: _comments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          'No comments yet · Be the first',
                          style: TextStyle(color: AdaptivePalette.muted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 11),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return _CommentTile(
                          key: Key('feed-comment-${comment.id}'),
                          comment: comment,
                          isHelpful: _helpfulCommentIds.contains(comment.id),
                          // Students cannot mark their own comments as Helpful.
                          onToggleHelpful: comment.own
                              ? null
                              : () => _toggleHelpful(comment.id),
                          onDelete: comment.own ? () => _delete(comment) : null,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('feed-comment-input'),
                    controller: _controller,
                    maxLength: 500,
                    maxLines: 1,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment (demo)',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 9),
                IconButton.filled(
                  key: const Key('feed-comment-send'),
                  onPressed: _submit,
                  tooltip: 'Add comment locally',
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    super.key,
    required this.comment,
    required this.isHelpful,
    required this.onToggleHelpful,
    this.onDelete,
  });

  final _DemoComment comment;
  final bool isHelpful;
  final VoidCallback? onToggleHelpful;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AdaptivePalette.paleBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            comment.isStaff
                ? Icons.verified_user_outlined
                : Icons.person_outline_rounded,
            size: 19,
            color: AdaptivePalette.navy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              color: AdaptivePalette.paleBlue,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AdaptivePalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      comment.author,
                      style: TextStyle(
                        color: AdaptivePalette.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (comment.isStaff)
                      Container(
                        key: const Key('feed-staff-badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AdaptivePalette.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AdaptivePalette.border),
                        ),
                        child: Text(
                          'Staff',
                          style: TextStyle(
                            color: AdaptivePalette.navy,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _commentTime(comment.createdAt),
                  style: TextStyle(color: AdaptivePalette.muted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  comment.message,
                  style: TextStyle(
                    color: AdaptivePalette.ink,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  runSpacing: 0,
                  children: [
                    if (onToggleHelpful != null)
                      TextButton.icon(
                        key: Key('feed-helpful-${comment.id}'),
                        onPressed: onToggleHelpful,
                        icon: Icon(
                          isHelpful
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_outlined,
                          size: 15,
                        ),
                        label: Text(isHelpful ? 'Helpful · 1' : 'Helpful'),
                        style: TextButton.styleFrom(
                          foregroundColor: isHelpful
                              ? AdaptivePalette.navy
                              : AdaptivePalette.muted,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        key: const Key('feed-delete-own-comment'),
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                        ),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: AdaptivePalette.muted,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
