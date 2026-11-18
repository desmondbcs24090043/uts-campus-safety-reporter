// Member 2 V2 integrated UI: V1 layout + ReportsBloc + DemoReportsRepository.
// Run: flutter run -d chrome -t lib/preview_integrated_main.dart
// Does not change lib/main.dart, V1 preview or Member 1 Authentication.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/reports/data/demo_reports_repository.dart';
import 'features/reports/presentation/reports_bloc.dart';
import 'features/reports/presentation/reports_event.dart';
import 'preview/app_appearance.dart';
import 'preview_integrated/preview_app_integrated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppAppearance.restore();
  runApp(const CampusSafetyIntegratedRoot());
}

class CampusSafetyIntegratedRoot extends StatelessWidget {
  const CampusSafetyIntegratedRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportsBloc(DemoReportsRepository())
        ..add(const ReportsRequested()),
      child: const CampusSafetyIntegratedPreviewApp(),
    );
  }
}
