import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/reports_repository.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc(this._repository) : super(const ReportsInitial()) {
    on<ReportsRequested>(_load);
    on<ReportsStatusFilterChanged>((event, emit) {
      final current = state;
      if (current is ReportsLoaded) {
        emit(current.copyWithStatus(event.status));
      }
    });
    on<ReportsSearchChanged>((event, emit) {
      final current = state;
      if (current is ReportsLoaded) {
        emit(current.copyWithQuery(event.query));
      }
    });
  }

  final ReportsRepository _repository;

  Future<void> _load(ReportsRequested event, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading());
    try {
      final records = await _repository.fetchMyReports();
      emit(ReportsLoaded(records: records));
    } catch (_) {
      // Do not expose raw database errors or personal data to students.
      emit(const ReportsFailure('Unable to load reports. Please try again.'));
    }
  }
}
