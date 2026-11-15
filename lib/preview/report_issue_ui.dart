import 'package:flutter/material.dart';

import '../data/models/report_category.dart';
import 'preview_theme.dart';

/// Member 2 UI-only hand-off for Member 3's incident reporting feature.
///
/// Uses the agreed ReportCategory enum. No GPS, camera, upload or database
/// calls are performed here. The sample location and review flow are clearly
/// labelled as demonstrations; Member 3 owns the real feature integration.
class ReportIssuePreviewPage extends StatefulWidget {
  const ReportIssuePreviewPage({super.key});

  @override
  State<ReportIssuePreviewPage> createState() => _ReportIssuePreviewPageState();
}

class _ReportIssuePreviewPageState extends State<ReportIssuePreviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  ReportCategory? _category;
  bool _sampleLocationSelected = false;

  static const _demoLatitude = 2.3150;
  static const _demoLongitude = 111.8300;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _showIntegrationNotice(String feature) {
    _showMessage('$feature is not connected in this demo. No photo was captured or uploaded.');
  }

  void _selectDemoLocation() {
    setState(() => _sampleLocationSelected = true);
    _showMessage('Demo location selected. Your real location was not accessed.');
  }

  void _chooseOnMapPreview() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.map_outlined, color: PreviewColours.navy, size: 32),
            const SizedBox(height: 16),
            const Text('Choose a location', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: PreviewColours.ink,
            )),
            const SizedBox(height: 8),
            const Text(
              'Interactive map selection is not available in this demo. '
              'You can use a sample location to preview the reporting flow.',
              style: TextStyle(color: PreviewColours.muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('confirm-demo-map-pin'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _selectDemoLocation();
              },
              style: FilledButton.styleFrom(
                backgroundColor: PreviewColours.navy,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Use demo location'),
            ),
          ],
        ),
      ),
    );
  }

  void _finishPreview() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const _ReportPreviewCompletePage(),
    ));
  }

  void _review() {
    if (_category == null) {
      _showMessage('Choose a category first.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_sampleLocationSelected) {
      _showMessage('Choose a location before reviewing your report.');
      return;
    }

    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          22, 6, 22, 22 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * .76),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Review your report',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: PreviewColours.ink),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Check your details before continuing.',
                  style: TextStyle(color: PreviewColours.muted, fontSize: 13.5),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PreviewColours.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: PreviewColours.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReviewLine(label: 'Issue category', value: _category!.label),
                      const Divider(color: PreviewColours.border, height: 22),
                      _ReviewLine(label: 'Description', value: _description.text.trim()),
                      const Divider(color: PreviewColours.border, height: 22),
                      const _ReviewLine(label: 'Photo', value: 'No photo attached'),
                      const Divider(color: PreviewColours.border, height: 22),
                      _ReviewLine(
                        label: 'Location',
                        value: 'Demo location · $_demoLatitude, $_demoLongitude',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 17, color: PreviewColours.muted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Preview only. No report, photo or location will be submitted.',
                        style: TextStyle(color: PreviewColours.muted, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('edit-report-preview'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Edit report'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        key: const Key('finish-demo-report'),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          if (!mounted) return;
                          _finishPreview();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: PreviewColours.navy,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Finish preview'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PreviewColours.background,
      appBar: AppBar(
        title: const Text('New report', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        leading: IconButton(
          key: const Key('report-back'),
          tooltip: 'Back to Dashboard',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 19),
            child: Center(child: _DemoBadge()),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              key: const Key('report-issue-form'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                const Text(
                  'Report an issue',
                  style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800, height: 1.1, color: PreviewColours.ink),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Tell us what happened so campus staff can review it.',
                  style: TextStyle(fontSize: 14, color: PreviewColours.muted, height: 1.45),
                ),
                const SizedBox(height: 19),
                _InfoNotice(
                  icon: Icons.info_outline_rounded,
                  message: 'For campus incident reporting only. This is not an emergency response service.',
                ),
                const SizedBox(height: 18),
                _FormCard(
                  heading: 'Issue category',
                  supporting: 'Choose the category that best describes the issue.',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 7,
                    children: ReportCategory.values.map((category) {
                      final selected = _category == category;
                      return ChoiceChip(
                        key: Key('category-${category.dbValue}'),
                        label: Text(category.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = category),
                        selectedColor: PreviewColours.paleBlue,
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        side: BorderSide(color: selected ? PreviewColours.navy : PreviewColours.border),
                        labelStyle: TextStyle(
                          color: selected ? PreviewColours.navy : PreviewColours.ink,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _FormCard(
                  heading: 'Description',
                  supporting: 'Describe the issue clearly, including what you observed.',
                  child: TextFormField(
                    key: const Key('report-description'),
                    controller: _description,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'For example, a corridor light is not working near the library...',
                      hintMaxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      final count = (value ?? '').trim().length;
                      if (count < 5) return 'Please enter at least 5 characters.';
                      if (count > 1000) return 'Please keep it under 1000 characters.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _FormCard(
                  heading: 'Photo',
                  supporting: 'Add a photo to help staff understand the issue (optional).',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                        decoration: BoxDecoration(
                          color: PreviewColours.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PreviewColours.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: PreviewColours.blue, size: 26),
                            SizedBox(height: 7),
                            Text('No photo attached', style: TextStyle(color: PreviewColours.ink, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('JPG, PNG or WEBP · up to 5 MB', style: TextStyle(color: PreviewColours.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('open-camera-preview'),
                              onPressed: () => _showIntegrationNotice('Camera'),
                              icon: const Icon(Icons.photo_camera_outlined, size: 18),
                              label: const Text('Camera'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('open-gallery-preview'),
                              onPressed: () => _showIntegrationNotice('Gallery'),
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: const Text('Gallery'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FormCard(
                  heading: 'Location',
                  supporting: 'Where did the issue occur?',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        key: const Key('report-location-panel'),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                        decoration: BoxDecoration(
                          color: PreviewColours.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PreviewColours.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sampleLocationSelected
                                  ? Icons.location_on_rounded
                                  : Icons.location_on_outlined,
                              color: _sampleLocationSelected
                                  ? PreviewColours.navy
                                  : PreviewColours.muted,
                              size: 27,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _sampleLocationSelected
                                  ? 'Demo location selected'
                                  : 'No location selected',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: PreviewColours.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _sampleLocationSelected
                                  ? '$_demoLatitude, $_demoLongitude · Not live GPS'
                                  : 'Add a location to help campus staff find the issue.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: PreviewColours.muted, fontSize: 12.5, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('use-gps-preview'),
                              onPressed: _selectDemoLocation,
                              icon: const Icon(Icons.my_location_rounded, size: 17),
                              label: const Text('Use GPS'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('choose-map-preview'),
                              onPressed: _chooseOnMapPreview,
                              icon: const Icon(Icons.map_outlined, size: 17),
                              label: const Text('Choose on map'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Demo only · Both options use sample coordinates, not your real location.',
                        style: TextStyle(fontSize: 11.5, height: 1.4, color: PreviewColours.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Preview only · No data will be saved or uploaded',
                    style: TextStyle(color: PreviewColours.muted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PreviewColours.border)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
                child: FilledButton(
                  key: const Key('report-preview-review'),
                  onPressed: _review,
                  style: FilledButton.styleFrom(
                    backgroundColor: PreviewColours.navy,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Review report'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.heading, required this.supporting, required this.child});
  final String heading;
  final String supporting;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: PreviewColours.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: const TextStyle(color: PreviewColours.ink, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(supporting, style: const TextStyle(color: PreviewColours.muted, fontSize: 12.5, height: 1.45)),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: PreviewColours.paleBlue,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Icon(icon, color: PreviewColours.navy, size: 19),
        const SizedBox(width: 11),
        Expanded(child: Text(message, style: const TextStyle(color: PreviewColours.navy, fontSize: 12.5, height: 1.4))),
      ],
    ),
  );
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(color: PreviewColours.paleBlue, borderRadius: BorderRadius.circular(50)),
    child: const Text('DEMO', style: TextStyle(color: PreviewColours.navy, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .7)),
  );
}

class _ReportPreviewCompletePage extends StatelessWidget {
  const _ReportPreviewCompletePage();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: PreviewColours.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Preview complete', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 19),
              child: Center(child: _DemoBadge()),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: const BoxDecoration(
                        color: PreviewColours.paleBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline_rounded,
                          size: 44, color: PreviewColours.navy),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'UI preview complete',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: PreviewColours.ink),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You have reached the end of the reporting preview.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: PreviewColours.muted, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const _InfoNotice(
                      icon: Icons.info_outline_rounded,
                      message: 'No report was submitted. No photo or location was sent or saved.',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('report-preview-home'),
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        icon: const Icon(Icons.home_outlined, size: 19),
                        label: const Text('Back to Home'),
                        style: FilledButton.styleFrom(
                          backgroundColor: PreviewColours.navy,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: PreviewColours.muted)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: PreviewColours.ink, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
