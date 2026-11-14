// Optional independent test entry for Member 2's V2 architecture.
// Run: flutter run -d chrome -t lib/preview_v2_main.dart
// Do not replace lib/main.dart or lib/preview_main.dart.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/reports/data/demo_reports_repository.dart';
import 'features/reports/presentation/reports_bloc.dart';
import 'features/reports/presentation/reports_event.dart';
import 'features/reports/presentation/reports_v2_preview_page.dart';
import 'preview/preview_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReportsV2PreviewApp());
}

class ReportsV2PreviewApp extends StatelessWidget {
  const ReportsV2PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Safety Reporter · V2 Architecture Demo',
      debugShowCheckedModeBanner: false,
      theme: buildPreviewTheme(),
      home: BlocProvider(
        create: (context) => ReportsBloc(
          DemoReportsRepository(simulatedLatency: const Duration(milliseconds: 150)),
        )..add(const ReportsRequested()),
        child: const ReportsV2PreviewPage(),
      ),
    );
  }
}
