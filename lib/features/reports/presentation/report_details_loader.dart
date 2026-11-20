import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/incident_report.dart';
import '../../../data/repositories/incident_report_repository.dart';
import '../../../data/repositories/repository_exception.dart';

enum ReportDetailsStatus {
  loading,
  loaded,
  notFound,
  permissionDenied,
  failure,
  identityChanged,
}

class ReportDetailsState {
  const ReportDetailsState(this.status, {this.report});

  final ReportDetailsStatus status;
  final IncidentReport? report;
}

/// Page-scoped reads. Identity observation never changes Authentication state.
class ReportDetailsLoader extends ChangeNotifier {
  ReportDetailsLoader({
    required this.reportId,
    required this.repository,
    required this.currentUserId,
    required Stream<String?> identityChanges,
  }) : _ownerId = currentUserId() {
    _identitySubscription = identityChanges.listen(
      _onIdentityChanged,
      onError: (Object error, StackTrace stackTrace) => _invalidateIdentity(),
    );
    unawaited(load());
  }

  final String reportId;
  final IncidentReportRepository repository;
  final String? Function() currentUserId;
  final String? _ownerId;
  late final StreamSubscription<String?> _identitySubscription;
  ReportDetailsState _state = const ReportDetailsState(
    ReportDetailsStatus.loading,
  );
  int _request = 0;
  bool _disposed = false;
  bool _identityInvalidated = false;

  ReportDetailsState get state => _state;

  bool get canRetry => !_identityInvalidated && _ownerId != null;

  void _onIdentityChanged(String? userId) {
    if (userId != _ownerId || currentUserId() != _ownerId) {
      _invalidateIdentity();
    }
  }

  void _invalidateIdentity() {
    if (_disposed || _identityInvalidated) return;
    _identityInvalidated = true;
    _request++;
    _setState(const ReportDetailsState(ReportDetailsStatus.identityChanged));
  }

  void _setState(ReportDetailsState state) {
    _state = state;
    notifyListeners();
  }

  bool _accept(int request) {
    if (_disposed || _identityInvalidated || request != _request) return false;
    if (currentUserId() != _ownerId) {
      _invalidateIdentity();
      return false;
    }
    return true;
  }

  Future<void> load() async {
    if (_disposed || _identityInvalidated) return;
    if (_ownerId == null || currentUserId() != _ownerId) {
      _invalidateIdentity();
      return;
    }
    final request = ++_request;
    _setState(const ReportDetailsState(ReportDetailsStatus.loading));
    try {
      final report = await repository.fetchReport(reportId);
      if (!_accept(request)) return;
      // A presentation guard supplements the existing server-side RLS contract.
      if (report.id != reportId || report.reporterId != _ownerId) {
        _setState(
          const ReportDetailsState(ReportDetailsStatus.permissionDenied),
        );
        return;
      }
      _setState(ReportDetailsState(ReportDetailsStatus.loaded, report: report));
    } catch (error) {
      if (!_accept(request)) return;
      final cause = error is RepositoryException ? error.cause : error;
      final code = cause is PostgrestException ? cause.code : null;
      final status = switch (code) {
        'PGRST116' => ReportDetailsStatus.notFound,
        '42501' => ReportDetailsStatus.permissionDenied,
        _ => ReportDetailsStatus.failure,
      };
      _setState(ReportDetailsState(status));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    unawaited(_identitySubscription.cancel());
    super.dispose();
  }
}
