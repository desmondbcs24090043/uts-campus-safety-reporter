import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'preview_theme.dart';
import 'video_preview.dart';

/// Local-only attachment selection. The parent owns this controller so the
/// selected files remain available when the report review sheet is opened.
/// No files are uploaded or stored in Supabase by this widget.
class NativeMediaSelection extends ChangeNotifier {
  final List<XFile> photos = [];
  XFile? video;

  void addPhoto(XFile file) {
    if (photos.length >= 3) return;
    photos.add(file);
    notifyListeners();
  }

  void setVideo(XFile file) {
    video = file;
    notifyListeners();
  }

  void removePhoto(XFile file) {
    photos.remove(file);
    notifyListeners();
  }

  void removeVideo() {
    video = null;
    notifyListeners();
  }

  String get summary {
    final photoText = photos.isEmpty
        ? 'No photos'
        : '${photos.length} ${photos.length == 1 ? 'photo' : 'photos'}';
    return '$photoText · ${video == null ? 'No video' : '1 video'}';
  }
}

class NativeMediaPickerCard extends StatefulWidget {
  const NativeMediaPickerCard({super.key, required this.selection});

  final NativeMediaSelection selection;

  @override
  State<NativeMediaPickerCard> createState() => _NativeMediaPickerCardState();
}

enum _MediaKind { photo, video }

class _NativeMediaPickerCardState extends State<NativeMediaPickerCard> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;
  static const int _maxPhotoBytes = 5 * 1024 * 1024;
  // Temporary client-side guard; Member 3/4 must approve server-side limits.
  static const int _maxVideoBytes = 25 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    widget.selection.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant NativeMediaPickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.selection, widget.selection)) {
      oldWidget.selection.removeListener(_onChanged);
      widget.selection.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.selection.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(ImageSource source) async {
    if (_picking) return;
    final kind = await showModalBottomSheet<_MediaKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Add media'),
              subtitle: Text('Choose a photo or a video'),
            ),
            ListTile(
              enabled: widget.selection.photos.length < 3,
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Photo'),
              onTap: () => Navigator.pop(context, _MediaKind.photo),
            ),
            ListTile(
              enabled: widget.selection.video == null,
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Video'),
              onTap: () => Navigator.pop(context, _MediaKind.video),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (!mounted || kind == null) return;
    setState(() => _picking = true);
    try {
      final XFile? file = kind == _MediaKind.photo
          ? await _picker.pickImage(source: source, imageQuality: 85)
          : await _picker.pickVideo(
              source: source,
              maxDuration: const Duration(seconds: 30),
            );
      if (file == null || !mounted) return;
      final size = await file.length();
      if (!mounted) return;
      if (kind == _MediaKind.photo) {
        final name = file.name.toLowerCase();
        if (!(name.endsWith('.jpg') ||
            name.endsWith('.jpeg') ||
            name.endsWith('.png') ||
            name.endsWith('.webp'))) {
          _notify('Please choose a JPG, PNG or WEBP photo.');
          return;
        }
        if (size > _maxPhotoBytes) {
          _notify('Photo must be 5 MB or smaller.');
          return;
        }
        if (widget.selection.photos.length >= 3) {
          _notify('Maximum 3 photos.');
          return;
        }
        widget.selection.addPhoto(file);
      } else {
        if (size > _maxVideoBytes) {
          _notify('Video must be 25 MB or smaller (temporary limit).');
          return;
        }
        widget.selection.setVideo(file);
      }
    } catch (error) {
      _notify(
        'Could not select media. Please check permissions and try again.',
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.selection.photos;
    final video = widget.selection.video;
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AdaptivePalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdaptivePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Media',
            style: TextStyle(
              color: AdaptivePalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Add photos or a video to help explain the issue (optional).',
            style: TextStyle(color: AdaptivePalette.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 15),
          if (photos.isEmpty && video == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              decoration: BoxDecoration(
                color: AdaptivePalette.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdaptivePalette.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.perm_media_outlined,
                    color: AdaptivePalette.blue,
                    size: 27,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No media attached',
                    style: TextStyle(
                      color: AdaptivePalette.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Photos or video',
                    style: TextStyle(
                      color: AdaptivePalette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          if (photos.isNotEmpty || video != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in photos)
                  _PhotoTile(
                    file: photo,
                    onRemove: () => widget.selection.removePhoto(photo),
                  ),
                if (video != null)
                  _VideoTile(
                    file: video,
                    onRemove: widget.selection.removeVideo,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.selection.summary,
              style: TextStyle(color: AdaptivePalette.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('native-media-camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _picking || (photos.length >= 3 && video != null)
                      ? null
                      : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('native-media-gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _picking || (photos.length >= 3 && video != null)
                      ? null
                      : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Up to 3 photos (5 MB each) and 1 short video (25 MB temporary limit). Local preview only; not uploaded.',
            style: TextStyle(color: AdaptivePalette.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.file, required this.onRemove});
  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 92,
          height: 92,
          child: FutureBuilder<Uint8List>(
            future: file.readAsBytes(),
            builder: (context, snapshot) => snapshot.hasData
                ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                : const Center(child: Icon(Icons.image_outlined)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: IconButton(
          tooltip: 'Remove photo',
          visualDensity: VisualDensity.compact,
          onPressed: onRemove,
          icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 22),
        ),
      ),
    ],
  );
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.file, required this.onRemove});
  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        width: 110,
        height: 92,
        decoration: BoxDecoration(
          color: AdaptivePalette.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdaptivePalette.border),
        ),
        child: Semantics(
          container: true,
          button: true,
          label: 'Play selected video',
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NativeVideoPreview(filePath: file.path),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  size: 33,
                  color: AdaptivePalette.blue,
                ),
                const SizedBox(height: 4),
                Text(
                  'Play video',
                  style: TextStyle(color: AdaptivePalette.ink, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: IconButton(
          tooltip: 'Remove video',
          visualDensity: VisualDensity.compact,
          onPressed: onRemove,
          icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 22),
        ),
      ),
    ],
  );
}
