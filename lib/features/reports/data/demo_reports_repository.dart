import '../domain/report_record.dart';
import '../domain/reports_repository.dart';

// Temporary, fictional records for Member 2's independent BLoC demo only.
// This duplicates V1's sample records intentionally; V1 remains unchanged.
class DemoReportsRepository implements ReportsRepository {
  DemoReportsRepository({
    this.simulatedLatency = Duration.zero,
    List<ReportRecord>? seed,
  }) : _seed = List<ReportRecord>.unmodifiable(seed ?? _sampleReports);

  final Duration simulatedLatency;
  final List<ReportRecord> _seed;

  @override
  Future<List<ReportRecord>> fetchMyReports() async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }
    return List<ReportRecord>.unmodifiable(_seed);
  }
}

final List<ReportRecord> _sampleReports = [
  ReportRecord(
    id: 'CSR-2026-001',
    title: 'Broken corridor light',
    category: 'Facilities',
    location: 'Library corridor (demo)',
    description: 'A corridor light is not working and the walkway is dim in the evening.',
    status: ReportStatus.pending,
    createdAt: DateTime(2026, 11, 10),
  ),
  ReportRecord(
    id: 'CSR-2026-002',
    title: 'Wet floor near stairs',
    category: 'Safety Hazard',
    location: 'Academic block, Level 1 (demo)',
    description: 'A slippery patch was noticed near a stairwell and may be a safety hazard.',
    status: ReportStatus.inProgress,
    createdAt: DateTime(2026, 11, 9),
  ),
  ReportRecord(
    id: 'CSR-2026-003',
    title: 'Damaged classroom chair',
    category: 'Facilities',
    location: 'Teaching room (demo)',
    description: 'A chair has a loose leg and should be inspected before it is used.',
    status: ReportStatus.pending,
    createdAt: DateTime(2026, 11, 8),
  ),
  ReportRecord(
    id: 'CSR-2026-004',
    title: 'Loose handrail',
    category: 'Safety Hazard',
    location: 'Stairway, Block A (demo)',
    description: 'A handrail was reported as loose. This is a fictional sample.',
    status: ReportStatus.resolved,
    createdAt: DateTime(2026, 11, 6),
  ),
  ReportRecord(
    id: 'CSR-2026-005',
    title: 'Water leak in washroom',
    category: 'Maintenance',
    location: 'Ground-floor washroom (demo)',
    description: 'Water was leaking from a pipe. This is a fictional sample.',
    status: ReportStatus.resolved,
    createdAt: DateTime(2026, 11, 4),
  ),
  ReportRecord(
    id: 'CSR-2026-006',
    title: 'Damaged campus bench',
    category: 'Facilities',
    location: 'Outdoor seating area (demo)',
    description: 'A bench was damaged. This is a fictional sample.',
    status: ReportStatus.resolved,
    createdAt: DateTime(2026, 11, 2),
  ),
];
