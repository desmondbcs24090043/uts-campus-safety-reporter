import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class NativeVideoPreview extends StatefulWidget {
  const NativeVideoPreview({super.key, required this.filePath});
  final String filePath;
  @override
  State<NativeVideoPreview> createState() => _NativeVideoPreviewState();
}

class _NativeVideoPreviewState extends State<NativeVideoPreview> {
  late final VideoPlayerController _controller;
  late final Future<void> _init;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath));
    _init = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Video preview')),
    body: FutureBuilder<void>(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to play this video.'));
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, child) => IconButton.filled(
                  tooltip: value.isPlaying ? 'Pause video' : 'Play video',
                  onPressed: () => value.isPlaying
                      ? _controller.pause()
                      : _controller.play(),
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
