import 'package:flutter/material.dart';

class NativeVideoPreview extends StatelessWidget {
  const NativeVideoPreview({super.key, required this.filePath});
  final String filePath;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Video preview')),
    body: const Center(
      child: Text('Local video playback is available on Android.'),
    ),
  );
}
