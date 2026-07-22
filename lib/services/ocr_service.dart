import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../core/data_dir.dart';

/// Result of an image capture: the recognized text (may be null) and the
/// on-device path of the saved original image (§7.6) so the extraction can
/// always be verified against what was photographed.
class OcrCapture {
  const OcrCapture({required this.text, required this.imagePath});
  final String? text;
  final String imagePath;
}

/// §11 image share-target — pick a photo/screenshot (e.g. of a WhatsApp note or
/// an invitation) and extract its text on-device via ML Kit Text Recognition.
/// The original image is kept locally. Fully on-device; nothing is uploaded (§1.1).
class OcrService {
  const OcrService();

  /// Picks an image from [source] and saves a durable copy, returning its path
  /// (no OCR). Used to attach a phone image/photo to a task (§11). Null if
  /// cancelled.
  Future<String?> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return null;
    return _persist(picked.path);
  }

  Future<String> _persist(String path) async {
    final dir = await saaraDataDir();
    final captures = Directory('${dir.path}/captures');
    if (!await captures.exists()) await captures.create(recursive: true);
    final ext = path.contains('.') ? path.split('.').last : 'jpg';
    final dest =
        '${captures.path}/cap_${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(path).copy(dest);
    return dest;
  }

  /// Picks an image from [source], saves a durable copy, and returns the text +
  /// image path. Null if the user cancelled.
  Future<OcrCapture?> capture(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return null;

    // Persist a copy — the picker's temp file can be cleaned up by the OS.
    final dest = await _persist(picked.path);

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(dest),
      );
      final text = result.text.trim();
      return OcrCapture(text: text.isEmpty ? null : text, imagePath: dest);
    } finally {
      await recognizer.close();
    }
  }
}
