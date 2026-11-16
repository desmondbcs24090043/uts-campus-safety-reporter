// UI-only test entry point: flutter run -d chrome -t lib/report_issue_ui_main.dart
import 'package:flutter/material.dart';
import 'preview/preview_theme.dart';
import 'preview/report_issue_ui.dart';

void main() => runApp(const ReportIssueUiApp());

class ReportIssueUiApp extends StatelessWidget {
  const ReportIssueUiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Campus Safety Reporter · Report UI Preview',
    theme: buildPreviewTheme(),
    debugShowCheckedModeBanner: false,
    home: Builder(
      builder: (innerContext) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(innerContext).push(
              MaterialPageRoute<void>(builder: (_) => const ReportIssuePreviewPage()),
            ),
            child: const Text('Open Report an Issue UI'),
          ),
        ),
      ),
    ),
  );
}
