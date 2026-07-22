import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../core/data_dir.dart';

/// §7.6 capture media helper — picks/records photo, video, and audio and
/// persists them on-device (nothing uploaded, §1.1).
class CaptureService {
  CaptureService();
  final ImagePicker _picker = ImagePicker();

  Future<Directory> _dir() async {
    final base = await saaraDataDir();
    final d = Directory('${base.path}/captures');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<String> _persist(String src, String prefix) async {
    final d = await _dir();
    final ext = src.contains('.') ? src.split('.').last : 'dat';
    final dest =
        '${d.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(src).copy(dest);
    return dest;
  }

  Future<String?> captureImage(ImageSource source) async {
    final x = await _picker.pickImage(source: source);
    return x == null ? null : _persist(x.path, 'img');
  }

  Future<String?> captureVideo(ImageSource source) async {
    final x = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 180),
    );
    return x == null ? null : _persist(x.path, 'vid');
  }

  /// A fresh file path for an audio recording (caller records into it).
  Future<String> newAudioPath() async {
    final d = await _dir();
    return '${d.path}/aud_${DateTime.now().microsecondsSinceEpoch}.m4a';
  }
}
