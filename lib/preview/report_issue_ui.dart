import 'package:flutter/material.dart';

import '../data/models/report_category.dart';
import 'demo_report_photos.dart';
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
  final _specificLocation = TextEditingController();
  final _photos = <DemoReportPhoto>[];
  bool get _photoLimitReached =>
      _photos.length == DemoReportPhoto.samples.length;
  ReportCategory? _category;
  String? _campusArea;

  static const _demoCampusAreas = ['Demo area A', 'Demo area B', 'Demo area C'];
  bool _sampleLocationSelected = false;

  static const _demoLatitude = 2.3150;
  static const _demoLongitude = 111.8300;

  @override
  void dispose() {
    _description.dispose();
    _specificLocation.dispose();
    super.dispose();
  }

  Future<void> _chooseDemoPhoto(String source) async {
    final photo = await showModalBottomSheet<DemoReportPhoto>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AdaptivePalette.surface,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a photo',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Choose a sample photo.'),
              const SizedBox(height: 12),
              for (final sample in DemoReportPhoto.samples)
                if (!_photos.contains(sample))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 48,
                      height: 40,
                      child: sample.image(),
                    ),
                    title: Text(sample.label),
                    onTap: () => Navigator.of(sheetContext).pop(sample),
                  ),
            ],
          ),
        ),
      ),
    );
    if (mounted && photo != null && !_photoLimitReached) {
      setState(() => _photos.add(photo));
    }
  }

  void _selectDemoLocation() {
    setState(() => _sampleLocationSelected = true);
    _showMessage('Sample location selected.');
  }

  void _chooseOnMapPreview() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AdaptivePalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          10,
          24,
          24 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.map_outlined, color: AdaptivePalette.navy, size: 32),
            const SizedBox(height: 16),
            Text(
              'Choose a location',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AdaptivePalette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a sample location to continue.',
              style: TextStyle(
                color: AdaptivePalette.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('confirm-demo-map-pin'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _selectDemoLocation();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AdaptivePalette.heroNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Use sample location'),
            ),
          ],
        ),
      ),
    );
  }

  void _finishPreview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _ReportPreviewCompletePage(),
      ),
    );
  }

  String? _descriptionError(String? value) {
    final count = (value ?? '').trim().length;
    if (count < 5) {
      return 'Please enter at least 5 characters.';
    }
    if (count > 1000) {
      return 'Please keep it under 1000 characters.';
    }
    return null;
  }

  void _review() {
    if (_category == null) {
      _showMessage('Choose a category first.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final descriptionError = _descriptionError(_description.text);
    if (descriptionError != null) {
      _showMessage(descriptionError);
      return;
    }
    if (_campusArea == null) {
      _showMessage('Choose a campus area before reviewing your report.');
      return;
    }
    final specificLocation = _specificLocation.text.trim();

    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AdaptivePalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          6,
          22,
          22 +
              MediaQuery.paddingOf(sheetContext).bottom +
              MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .76,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Review your report',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AdaptivePalette.ink,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Check your details before continuing.',
                  style: TextStyle(
                    color: AdaptivePalette.muted,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdaptivePalette.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AdaptivePalette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReviewLine(
                        label: 'Issue category',
                        value: _category!.label,
                      ),
                      Divider(color: AdaptivePalette.border, height: 22),
                      _ReviewLine(
                        label: 'Description',
                        value: _description.text.trim(),
                      ),
                      Divider(color: AdaptivePalette.border, height: 22),
                      _ReviewLine(
                        label: 'Photo',
                        value: switch (_photos.length) {
                          0 => 'No photo attached',
                          1 => '1 photo selected',
                          final count => '$count photos selected',
                        },
                      ),
                      if (_photos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        DemoPhotoStrip(photos: _photos),
                      ],
                      Divider(color: AdaptivePalette.border, height: 22),
                      _ReviewLine(label: 'Campus Area', value: _campusArea!),
                      if (specificLocation.isNotEmpty) ...[
                        Divider(color: AdaptivePalette.border, height: 22),
                        _ReviewLine(
                          label: 'Specific Location',
                          value: specificLocation,
                        ),
                      ],
                      if (_sampleLocationSelected) ...[
                        Divider(color: AdaptivePalette.border, height: 22),
                        const _ReviewLine(
                          label: 'Sample coordinates',
                          value: '$_demoLatitude, $_demoLongitude',
                        ),
                      ],
                    ],
                  ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
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
                          backgroundColor: AdaptivePalette.heroNavy,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
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
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdaptivePalette.background,
      appBar: AppBar(
        title: const Text(
          'New report',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
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
                Text(
                  'Report an issue',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: AdaptivePalette.ink,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Tell us what happened so campus staff can review it.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AdaptivePalette.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 19),
                _InfoNotice(
                  icon: Icons.info_outline_rounded,
                  message: 'For campus incident reporting only. This is not an emergency response service.',
                ),
                const SizedBox(height: 18),
                _FormCard(
                  heading: 'Issue category',
                  supporting:
                      'Choose the category that best describes the issue.',
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
                        selectedColor: AdaptivePalette.paleBlue,
                        backgroundColor: AdaptivePalette.surface,
                        showCheckmark: false,
                        side: BorderSide(
                          color: selected
                              ? AdaptivePalette.navy
                              : AdaptivePalette.border,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? AdaptivePalette.navy
                              : AdaptivePalette.ink,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                    validator: _descriptionError,
                  ),
                ),
                const SizedBox(height: 14),
                _FormCard(
                  heading: 'Photo',
                  supporting: 'Add up to 3 photos to help staff understand the issue (optional).',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_photos.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 22,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AdaptivePalette.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AdaptivePalette.border),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AdaptivePalette.blue,
                                size: 26,
                              ),
                              SizedBox(height: 7),
                              Text(
                                'No photo attached',
                                style: TextStyle(
                                  color: AdaptivePalette.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'JPG, PNG or WEBP · up to 5 MB each',
                                style: TextStyle(
                                  color: AdaptivePalette.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        DemoPhotoStrip(
                          photos: _photos,
                          onRemove: (photo) =>
                              setState(() => _photos.remove(photo)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _photoLimitReached
                              ? '3 photos · Limit reached'
                              : '${_photos.length} of 3 photos',
                          style: TextStyle(
                            color: AdaptivePalette.muted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'JPG, PNG or WEBP · up to 5 MB each',
                          style: TextStyle(
                            color: AdaptivePalette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('open-camera-preview'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              onPressed: _photoLimitReached
                                  ? null
                                  : () => _chooseDemoPhoto('camera'),
                              icon: const Icon(
                                Icons.photo_camera_outlined,
                                size: 18,
                              ),
                              label: const Text('Camera'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('open-gallery-preview'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              onPressed: _photoLimitReached
                                  ? null
                                  : () => _chooseDemoPhoto('gallery'),
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
                      DropdownButtonFormField<String>(
                        key: const Key('report-campus-area'),
                        initialValue: _campusArea,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Campus Area (required)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final area in _demoCampusAreas)
                            DropdownMenuItem(value: area, child: Text(area)),
                        ],
                        onChanged: (value) => _campusArea = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('report-specific-location'),
                        controller: _specificLocation,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        minLines: 1,
                        decoration: const InputDecoration(
                          labelText: 'Specific Location (optional)',
                          hintText: 'Room, floor or nearby landmark',
                          hintMaxLines: 2,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('use-gps-preview'),
                              onPressed: _selectDemoLocation,
                              icon: const Icon(
                                Icons.my_location_rounded,
                                size: 17,
                              ),
                              label: const Text('Use GPS'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_sampleLocationSelected) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Sample location selected',
                          key: const Key('report-location-panel'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AdaptivePalette.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Sample coordinates: $_demoLatitude, $_demoLongitude',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AdaptivePalette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AdaptivePalette.surface,
          border: Border(top: BorderSide(color: AdaptivePalette.border)),
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
                    backgroundColor: AdaptivePalette.heroNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
  const _FormCard({
    required this.heading,
    required this.supporting,
    required this.child,
  });
  final String heading;
  final String supporting;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: AdaptivePalette.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AdaptivePalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: TextStyle(
            color: AdaptivePalette.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          supporting,
          style: TextStyle(
            color: AdaptivePalette.muted,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
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
      color: AdaptivePalette.paleBlue,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Icon(icon, color: AdaptivePalette.navy, size: 19),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: AdaptivePalette.navy,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: AdaptivePalette.paleBlue,
      borderRadius: BorderRadius.circular(50),
    ),
    child: Text(
      'DEMO',
      style: TextStyle(
        color: AdaptivePalette.navy,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: .7,
      ),
    ),
  );
}

class _ReportPreviewCompletePage extends StatelessWidget {
  const _ReportPreviewCompletePage();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdaptivePalette.background,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text(
        'Preview complete',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
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
                  decoration: BoxDecoration(
                    color: AdaptivePalette.paleBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 44,
                    color: AdaptivePalette.navy,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'UI preview complete',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AdaptivePalette.ink,
                  ),
                ),
                const SizedBox(height: 20),
                const _InfoNotice(
                  icon: Icons.info_outline_rounded,
                  message: 'No report was submitted.',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('report-preview-home'),
                    onPressed: () =>
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home_outlined, size: 19),
                    label: const Text('Back to Home'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdaptivePalette.heroNavy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
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
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AdaptivePalette.muted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: AdaptivePalette.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
