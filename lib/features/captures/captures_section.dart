import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/platform.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../../services/capture_service.dart';
import 'capture_viewers.dart';
import 'record_audio_sheet.dart';

/// §7.6 Captures — record/attach a text note, photo, audio, or video against a
/// task. Everything is stored on-device (§1.1); nothing is uploaded.
class CapturesSection extends ConsumerWidget {
  const CapturesSection({super.key, required this.taskId});
  final String taskId;

  Future<void> _insert(
    WidgetRef ref, {
    required CaptureType type,
    String? mediaPath,
    String? textContent,
    String? caption,
    int? durationSec,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    int size = 0;
    if (mediaPath != null) {
      try {
        size = await File(mediaPath).length();
      } catch (_) {}
    }
    await db
        .into(db.captures)
        .insert(
          CapturesCompanion.insert(
            id: const Uuid().v4(),
            type: type,
            mediaPath: Value(mediaPath),
            textContent: Value(textContent),
            caption: Value(caption),
            durationSec: Value(durationSec),
            sizeBytes: Value(size),
            attachedType: AttachedType.task,
            attachedId: taskId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    ref.invalidate(capturesForTaskProvider(taskId));
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Text note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 6,
          minLines: 3,
          decoration: const InputDecoration(
            hintText: 'Type a note against this task…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) {
      await _insert(ref, type: CaptureType.text, textContent: text);
    }
  }

  Future<void> _addPhoto(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final path = await CaptureService().captureImage(source);
    if (path != null) {
      await _insert(ref, type: CaptureType.image, mediaPath: path);
    }
  }

  Future<void> _addVideo(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final path = await CaptureService().captureVideo(source);
    if (path != null) {
      await _insert(ref, type: CaptureType.video, mediaPath: path);
    }
  }

  Future<void> _addAudio(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String? path, int seconds})>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const RecordAudioSheet(),
    );
    if (result?.path != null) {
      await _insert(
        ref,
        type: CaptureType.audio,
        mediaPath: result!.path,
        durationSec: result.seconds,
      );
    }
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notes),
              title: const Text('Text note'),
              onTap: () {
                Navigator.pop(ctx);
                _addNote(context, ref);
              },
            ),
            if (supportsCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addPhoto(context, ref, ImageSource.camera);
                },
              ),
            if (supportsFilePick)
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addPhoto(context, ref, ImageSource.gallery);
                },
              ),
            if (supportsVideo)
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record video'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addVideo(context, ref, ImageSource.camera);
                },
              ),
            if (supportsFilePick)
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Pick video'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addVideo(context, ref, ImageSource.gallery);
                },
              ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Record audio'),
              onTap: () {
                Navigator.pop(ctx);
                _addAudio(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(WidgetRef ref, Capture c) async {
    final db = ref.read(appDatabaseProvider);
    if (c.mediaPath != null) {
      try {
        final f = File(c.mediaPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await (db.delete(db.captures)..where((t) => t.id.equals(c.id))).go();
    ref.invalidate(capturesForTaskProvider(taskId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(capturesForTaskProvider(taskId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Captures', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              onPressed: () => _showAddSheet(context, ref),
            ),
          ],
        ),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text(
            'Could not load captures: $e',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No captures yet — record a note, photo, audio or '
                  'video against this task.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return Column(
              children: [
                for (final c in items)
                  _CaptureTile(capture: c, onDelete: () => _delete(ref, c)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile({required this.capture, required this.onDelete});
  final Capture capture;
  final VoidCallback onDelete;

  IconData get _icon => switch (capture.type) {
    CaptureType.text => Icons.notes,
    CaptureType.image => Icons.photo,
    CaptureType.audio => Icons.mic,
    CaptureType.video => Icons.videocam,
  };

  String _duration() {
    final d = capture.durationSec;
    if (d == null) return '';
    final m = (d ~/ 60).toString().padLeft(2, '0');
    final s = (d % 60).toString().padLeft(2, '0');
    return ' · $m:$s';
  }

  String get _title => switch (capture.type) {
    CaptureType.text => capture.textContent ?? 'Note',
    CaptureType.image => 'Photo',
    CaptureType.audio => 'Audio note',
    CaptureType.video => 'Video',
  };

  void _open(BuildContext context) {
    switch (capture.type) {
      case CaptureType.text:
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Note'),
            content: SingleChildScrollView(
              child: Text(capture.textContent ?? ''),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      case CaptureType.image:
        if (capture.mediaPath != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImageViewerScreen(path: capture.mediaPath!),
            ),
          );
        }
      case CaptureType.video:
        if (capture.mediaPath != null) {
          if (supportsVideoPlayback) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(path: capture.mediaPath!),
              ),
            );
          } else {
            // video_player has no Windows implementation — hand the clip to
            // whatever the OS uses to play video.
            launchUrl(Uri.file(capture.mediaPath!));
          }
        }
      case CaptureType.audio:
        break; // played inline via the trailing button
    }
  }

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('d MMM, HH:mm').format(capture.createdAt);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(_icon, size: 20)),
      title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('$when${_duration()}'),
      onTap: capture.type == CaptureType.audio ? null : () => _open(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (capture.type == CaptureType.audio && capture.mediaPath != null)
            AudioPlayButton(path: capture.mediaPath!),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete capture?'),
                  content: const Text('This removes the file from the device.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) onDelete();
            },
          ),
        ],
      ),
    );
  }
}
