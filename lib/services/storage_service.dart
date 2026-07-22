import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, OrderingMode, Value;

import '../core/data_dir.dart';
import '../data/database.dart';
import '../domain/enums.dart';

/// What Saara's media is costing on this device (§1.1, §7.6).
class StorageUsage {
  StorageUsage({
    required this.imageBytes,
    required this.videoBytes,
    required this.audioBytes,
    required this.orphanBytes,
    required this.orphanCount,
    required this.missingCount,
    required this.captureCount,
  });

  final int imageBytes;
  final int videoBytes;
  final int audioBytes;

  /// Files sitting in the media folder that no row points at — safe to delete.
  final int orphanBytes;
  final int orphanCount;

  /// Rows whose file has gone (cloud-cleaned, manually deleted, restored
  /// device). Worth surfacing: the capture will never play again.
  final int missingCount;

  final int captureCount;

  int get totalBytes => imageBytes + videoBytes + audioBytes + orphanBytes;
}

/// §7.6 media lives **on the device**, next to the encrypted database — nothing
/// is uploaded. Captures and attachments are *copied* into `<data>/captures`
/// on save, so a task never points at a temp file the OS may reclaim.
///
/// Because that folder only grows (a 3-minute video is tens of MB), this
/// service exists to make the cost visible and reclaimable.
class StorageService {
  StorageService(this.db);
  final AppDatabase db;

  Future<Directory> mediaDir() async {
    final base = await saaraDataDir();
    final d = Directory('${base.path}/captures');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<StorageUsage> measure() async {
    final dir = await mediaDir();
    final captures = await db.select(db.captures).get();
    final tasks = await db.select(db.tasks).get();

    // Every path the database still cares about.
    final referenced = <String>{
      for (final c in captures)
        if (c.mediaPath != null) _key(c.mediaPath!),
      for (final t in tasks)
        if (t.attachmentImagePath != null) _key(t.attachmentImagePath!),
    };

    var image = 0, video = 0, audio = 0, orphanBytes = 0, orphanCount = 0;
    final onDisk = <String>{};

    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final len = await entity.length();
      final key = _key(entity.path);
      onDisk.add(key);
      if (!referenced.contains(key)) {
        orphanBytes += len;
        orphanCount++;
        continue;
      }
      switch (_kindOf(entity.path)) {
        case CaptureType.video:
          video += len;
        case CaptureType.audio:
          audio += len;
        default:
          image += len;
      }
    }

    final missing = referenced.where((r) => !onDisk.contains(r)).length;

    return StorageUsage(
      imageBytes: image,
      videoBytes: video,
      audioBytes: audio,
      orphanBytes: orphanBytes,
      orphanCount: orphanCount,
      missingCount: missing,
      captureCount: captures.length,
    );
  }

  /// Deletes media files nothing references. Returns bytes reclaimed.
  Future<int> deleteOrphans() async {
    final dir = await mediaDir();
    final captures = await db.select(db.captures).get();
    final tasks = await db.select(db.tasks).get();
    final referenced = <String>{
      for (final c in captures)
        if (c.mediaPath != null) _key(c.mediaPath!),
      for (final t in tasks)
        if (t.attachmentImagePath != null) _key(t.attachmentImagePath!),
    };

    var freed = 0;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      if (referenced.contains(_key(entity.path))) continue;
      try {
        freed += await entity.length();
        await entity.delete();
      } catch (_) {
        // A locked/streaming file just stays — try again next time.
      }
    }
    return freed;
  }

  /// §7.6 free space by dropping media from tasks finished more than [days]
  /// ago. Returns bytes reclaimed.
  ///
  /// What goes: the **raw file** only — the AI-extraction image (its job ended
  /// when the fields were filled) and photo/video/audio captures. What stays:
  /// the task, its integrity ledger, notes, and **text** captures. The record
  /// of *whether you kept your word* is never touched; only the bulky evidence
  /// of a job already done.
  /// When [archiveDir] is set the file is **moved** there and the row keeps
  /// pointing at its new home (so it still opens while that drive is attached);
  /// otherwise it's deleted. Either way the device's own storage is reclaimed.
  Future<int> purgeCompletedMedia(int days, {String? archiveDir}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    var freed = 0;

    Directory? archive;
    if (archiveDir != null && archiveDir.trim().isNotEmpty) {
      archive = Directory(archiveDir);
      if (!await archive.exists()) await archive.create(recursive: true);
    }

    final done = await (db.select(
      db.tasks,
    )..where((t) => t.status.equalsValue(TaskStatus.completed))).get();
    final stale = done
        .where((t) => (t.completedAt ?? t.updatedAt).isBefore(cutoff))
        .toList();
    if (stale.isEmpty) return 0;

    for (final t in stale) {
      // 1. the raw AI-extraction image attached to the task
      final img = t.attachmentImagePath;
      if (img != null) {
        final moved = archive == null ? null : await _moveTo(img, archive);
        freed += archive == null ? await _deleteFile(img) : (moved?.bytes ?? 0);
        await (db.update(db.tasks)..where((x) => x.id.equals(t.id))).write(
          TasksCompanion(attachmentImagePath: Value(moved?.path)),
        );
      }
      // 2. media captures under it (text captures are kept — they're notes)
      final caps =
          await (db.select(db.captures)
                ..where((c) => c.attachedId.equals(t.id))
                ..where((c) => c.attachedType.equalsValue(AttachedType.task)))
              .get();
      for (final c in caps) {
        if (c.type == CaptureType.text || c.mediaPath == null) continue;
        if (archive == null) {
          freed += await _deleteFile(c.mediaPath!);
          await (db.delete(db.captures)..where((x) => x.id.equals(c.id))).go();
        } else {
          final moved = await _moveTo(c.mediaPath!, archive);
          if (moved == null) continue; // couldn't move — leave it alone
          freed += moved.bytes;
          // Keep the row: the capture still belongs to the task, it just lives
          // on the archive drive now (§3.4 archived / archive_uri).
          await (db.update(db.captures)..where((x) => x.id.equals(c.id))).write(
            CapturesCompanion(
              mediaPath: Value(moved.path),
              archived: const Value(true),
              archiveUri: Value(moved.path),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    }
    return freed;
  }

  /// Moves a file into [dir], keeping its name unique. Falls back to copy+delete
  /// because `rename` fails across volumes (the whole point here is an *external*
  /// drive). Returns null if it couldn't be moved — the original is left intact.
  Future<({String path, int bytes})?> _moveTo(String src, Directory dir) async {
    try {
      final f = File(src);
      if (!await f.exists()) return null;
      final bytes = await f.length();
      final name = _key(src);
      var dest = '${dir.path}${Platform.pathSeparator}$name';
      var n = 1;
      while (await File(dest).exists()) {
        dest = '${dir.path}${Platform.pathSeparator}${n++}_$name';
      }
      try {
        await f.rename(dest); // same volume: instant
      } catch (_) {
        await f.copy(dest); // cross-volume
        await f.delete();
      }
      return (path: dest, bytes: bytes);
    } catch (_) {
      return null;
    }
  }

  Future<int> _deleteFile(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return 0;
      final len = await f.length();
      await f.delete();
      return len;
    } catch (_) {
      return 0;
    }
  }

  /// The biggest captures, for "what's actually eating the space".
  Future<List<({Capture capture, int bytes})>> largest({int limit = 20}) async {
    final rows =
        await (db.select(db.captures)..orderBy([
              (c) => OrderingTerm(
                expression: c.createdAt,
                mode: OrderingMode.desc,
              ),
            ]))
            .get();
    final out = <({Capture capture, int bytes})>[];
    for (final c in rows) {
      if (c.mediaPath == null) continue;
      try {
        final f = File(c.mediaPath!);
        if (await f.exists()) {
          out.add((capture: c, bytes: await f.length()));
        }
      } catch (_) {}
    }
    out.sort((a, b) => b.bytes.compareTo(a.bytes));
    return out.take(limit).toList();
  }

  /// Deletes one capture: its row and its file.
  Future<void> deleteCapture(Capture c) async {
    if (c.mediaPath != null) {
      try {
        final f = File(c.mediaPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await (db.delete(db.captures)..where((t) => t.id.equals(c.id))).go();
  }

  /// Compare by filename: a device restore or a moved data folder changes the
  /// directory prefix, so full-path matching would report false orphans.
  static String _key(String path) =>
      path.replaceAll('\\', '/').split('/').last.toLowerCase();

  static CaptureType _kindOf(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.mp4') || p.endsWith('.mov') || p.endsWith('.avi')) {
      return CaptureType.video;
    }
    if (p.endsWith('.m4a') || p.endsWith('.aac') || p.endsWith('.wav')) {
      return CaptureType.audio;
    }
    return CaptureType.image;
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
