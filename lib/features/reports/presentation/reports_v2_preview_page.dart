import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/report_record.dart';
import 'reports_bloc.dart';
import 'reports_event.dart';
import 'reports_state.dart';

// Separate state-management demo. This is NOT the released Dashboard V1 UI.
class ReportsV2PreviewPage extends StatelessWidget {
  const ReportsV2PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports · V2 Architecture')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'BLoC + Demo Repository — not connected to Supabase',
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 20),
              Expanded(child: BlocBuilder<ReportsBloc, ReportsState>(
                builder: (context, state) {
                  if (state is ReportsInitial || state is ReportsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ReportsFailure) {
                    return Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.read<ReportsBloc>().add(const ReportsRequested()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ));
                  }
                  final loaded = state as ReportsLoaded;
                  final visible = loaded.visibleRecords;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const Key('v2-search'),
                        decoration: const InputDecoration(
                          labelText: 'Search demo reports',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (text) => context.read<ReportsBloc>().add(ReportsSearchChanged(text)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _statusChip(context, loaded, null, 'All', 'v2-filter-all'),
                        _statusChip(context, loaded, ReportStatus.pending, 'Pending', 'v2-filter-pending'),
                        _statusChip(context, loaded, ReportStatus.inProgress, 'In Progress', 'v2-filter-progress'),
                        _statusChip(context, loaded, ReportStatus.resolved, 'Resolved', 'v2-filter-resolved'),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Text('${visible.length} demo reports'),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => context.read<ReportsBloc>().add(const ReportsRequested()),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reload'),
                        ),
                      ]),
                      const Divider(),
                      Expanded(
                        child: visible.isEmpty
                            ? Center(child: Text(loaded.hasNoReports
                                ? 'No reports available'
                                : 'No matching reports'))
                            : ListView.builder(
                                itemCount: visible.length,
                                itemBuilder: (context, index) {
                                  final report = visible[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(report.title),
                                      subtitle: Text('${report.id} · ${report.location}'),
                                      trailing: Text(report.status.label),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, ReportsLoaded loaded,
      ReportStatus? status, String label, String key) {
    return ChoiceChip(
      key: Key(key),
      label: Text(label),
      selected: loaded.statusFilter == status,
      onSelected: (_) => context.read<ReportsBloc>().add(ReportsStatusFilterChanged(status)),
    );
  }
}
