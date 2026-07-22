import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen video playback for a captured clip (§7.6). File stays on-device.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.path, this.title});
  final String path;
  final String? title;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _c.play();
        }
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'Video'),
      ),
      body: Center(
        child: _ready
            ? AspectRatio(
                aspectRatio: _c.value.aspectRatio == 0
                    ? 16 / 9
                    : _c.value.aspectRatio,
                child: VideoPlayer(_c),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      floatingActionButton: _ready
          ? FloatingActionButton(
              onPressed: () =>
                  setState(() => _c.value.isPlaying ? _c.pause() : _c.play()),
              child: Icon(_c.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}

/// Inline play/pause button + progress for a captured audio note (§7.6).
class AudioPlayButton extends StatefulWidget {
  const AudioPlayButton({super.key, required this.path});
  final String path;

  @override
  State<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play(DeviceFileSource(widget.path));
      setState(() => _playing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
      tooltip: _playing ? 'Pause' : 'Play',
      onPressed: _toggle,
    );
  }
}

/// Full-screen pinch-to-zoom viewer for a captured photo (§7.6).
class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.path, this.title});
  final String path;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title ?? 'Photo'),
      ),
      body: Center(
        child: InteractiveViewer(maxScale: 5, child: Image.file(File(path))),
      ),
    );
  }
}
