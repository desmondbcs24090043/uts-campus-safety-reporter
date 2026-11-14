// All entries in this file are fictional demonstration data.
// Nothing here represents verified incidents at UTS.
import 'package:flutter/material.dart';

enum ReportStatus { pending, inProgress, resolved }

extension ReportStatusLabel on ReportStatus {
  String get label => switch (this) {
    ReportStatus.pending => 'Pending',
    ReportStatus.inProgress => 'In Progress',
    ReportStatus.resolved => 'Resolved',
  };
}

class DemoReport {
  const DemoReport({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.icon,
  });

  final String id;
  final String title;
  final String category;
  final String location;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final IconData icon;
}

final List<DemoReport> demoReports = List.unmodifiable([
  DemoReport(
    id: 'CSR-2026-001',
    title: 'Broken corridor light',
    category: 'Facilities',
    location: 'Library corridor (demo)',
    description: 'A corridor light is not working and the walkway is dim in the evening.',
    status: ReportStatus.pending,
    createdAt: DateTime(2026, 11, 10),
    icon: Icons.lightbulb_outline_rounded,
  ),
  DemoReport(
    id: 'CSR-2026-002',
    title: 'Wet floor near stairs',
    category: 'Safety Hazard',
    location: 'Academic block, Level 1 (demo)',
    description: 'A slippery patch was noticed near a stairwell and may be a safety hazard.',
    status: ReportStatus.inProgress,
    createdAt: DateTime(2026, 11, 9),
    icon: Icons.warning_amber_rounded,
  ),
  DemoReport(
    id: 'CSR-2026-003',
    title: 'Damaged classroom chair',
    category: 'Facilities',
    location: 'Teaching room (demo)',
    description: 'A chair has a loose leg and should be inspected before it is used.',
    status: ReportStatus.pending,
    createdAt: DateTime(2026, 11, 8),
    icon: Icons.chair_alt_outlined,
  ),
  DemoReport(
    id: 'CSR-2026-004',
    title: 'Loose handrail',
    category: 'Safety Hazard',
    location: 'Stairway, Block A (demo)',
    description: 'A handrail was reported as loose. The issue was marked resolved for this demo.',
    status: ReportStatus.resolved,
    createdAt: DateTime(2026, 11, 6),
    icon: Icons.handyman_outlined,
  ),
  DemoReport(
    id: 'CSR-2026-005',
    title: 'Water leak in washroom',
    category: 'Maintenance',
    location: 'Ground-floor washroom (demo)',
    description: 'Water was leaking from a pipe. This sample report is shown as resolved.',
    status: ReportStatus.resolved,
    createdAt: DateTime(2026, 11, 4),
    icon: Icons.water_drop_outlined,
  ),
  DemoReport(
    id: 'CSR-2026-006',
    title: 'Damaged campus bench',
    category: 'Facilities',
    location: 'Outdoor seating area (demo)',
    description: 'A bench was damaged. This example is not a real campus report.',
    status: ReportStatus.resolved,
    createdAt: DateTime(2026, 11, 2),
    icon: Icons.park_outlined,
  ),
]);

String formatDemoDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
