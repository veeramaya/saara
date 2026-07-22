import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../services/capture_service.dart';

/// §7.6 audio capture — records to an on-device file and returns its path +
/// duration. Auto-stops at 600 s (§16). No upload.
class RecordAudioSheet extends StatefulWidget {
  const RecordAudioSheet({super.key});

  @override
  State<RecordAudioSheet> createState() => _RecordAudioSheetState();
}

class _RecordAudioSheetState extends State<RecordAudioSheet> {
  final _rec = AudioRecorder();
  Timer? _timer;
  int _seconds = 0;
  bool _recording = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!await _rec.hasPermission()) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _path = await CaptureService().newAudioPath();
    await _rec.start(const RecordConfig(), path: _path!);
    setState(() => _recording = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      if (_seconds >= 600) _stop();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final path = await _rec.stop();
    if (mounted) {
      Navigator.of(context).pop((path: path ?? _path, seconds: _seconds));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rec.dispose();
    super.dispose();
  }

  String get _fmt {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            size: 48,
            color: _recording ? scheme.error : scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            _fmt,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontFeatures: const []),
          ),
          const SizedBox(height: 6),
          Text(
            _recording ? 'Recording…' : 'Starting…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stop & save'),
            onPressed: _recording ? _stop : null,
          ),
        ],
      ),
    );
  }
}
