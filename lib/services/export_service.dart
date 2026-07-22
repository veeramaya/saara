import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';

/// §1.1 data portability — "Export all my data". Bundles every table plus all
/// capture media into a single local `.zip`, entirely on-device. Nothing is
/// uploaded; the file only leaves the phone if the user picks a share target.
/// Secrets (AI keys, Google sync tokens) live in the Keystore and are **not**
/// exported.
class ExportService {
  ExportService(this.db);
  final AppDatabase db;

  List<Map<String, dynamic>> _json(List<dynamic> rows) => [
    for (final r in rows) (r as dynamic).toJson() as Map<String, dynamic>,
  ];

  Future<Map<String, dynamic>> _buildData() async {
    return {
      'app': 'Saara',
      'schemaVersion': db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'note':
          'Your Saara data, exported on-device. AI keys and sync tokens are '
          'stored in the device keystore and are intentionally not included.',
      'areas': _json(await db.select(db.areas).get()),
      'measurableResults': _json(await db.select(db.measurableResults).get()),
      'measurableLogs': _json(await db.select(db.measurableLogs).get()),
      'tasks': _json(await db.select(db.tasks).get()),
      'taskParticipants': _json(await db.select(db.taskParticipants).get()),
      'taskTransitions': _json(await db.select(db.taskTransitions).get()),
      'captures': _json(await db.select(db.captures).get()),
      'committedListeners': _json(await db.select(db.committedListeners).get()),
      'listenerFeedbacks': _json(await db.select(db.listenerFeedbacks).get()),
      'saaraGroups': _json(await db.select(db.saaraGroups).get()),
      'dayLogs': _json(await db.select(db.dayLogs).get()),
      'healthSnapshots': _json(await db.select(db.healthSnapshots).get()),
      'settings': _json(await db.select(db.settings).get()),
    };
  }

  /// Builds the export `.zip` in a temp dir and returns its path.
  Future<String> exportZip() async {
    final data = await _buildData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final jsonBytes = utf8.encode(jsonStr);

    final tmp = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final zipPath = p.join(tmp.path, 'saara-export-$stamp.zip');

    final enc = ZipFileEncoder();
    enc.create(zipPath);
    enc.addArchiveFile(
      ArchiveFile('saara-data.json', jsonBytes.length, jsonBytes),
    );

    // Bundle capture media that still exists on disk, under media/.
    final caps = await db.select(db.captures).get();
    for (final c in caps) {
      final path = c.mediaPath;
      if (path == null) continue;
      final f = File(path);
      if (await f.exists()) {
        enc.addFile(f, 'media/${p.basename(path)}');
      }
    }
    enc.close();
    return zipPath;
  }
}
