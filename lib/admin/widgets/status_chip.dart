import 'package:flutter/material.dart';

import '../../data/models/report_status.dart';

/// Coloured pill showing a report status. Same colours everywhere.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final ReportStatus status;

  static Color colorFor(ReportStatus status) => switch (status) {
        ReportStatus.pending => const Color(0xFFB26A00),
        ReportStatus.inProgress => const Color(0xFF1565C0),
        ReportStatus.resolved => const Color(0xFF2E7D32),
      };

  static IconData iconFor(ReportStatus status) => switch (status) {
        ReportStatus.pending => Icons.schedule,
        ReportStatus.inProgress => Icons.build_circle_outlined,
        ReportStatus.resolved => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(status), size: 14, color: color),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Simple local date/time formatting without extra packages.
String formatDateTime(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
