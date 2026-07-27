import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;

import '../data/database.dart';

/// Small key/value settings over the §3.6 Settings table. Used for the Google
/// auto-sync toggle and the last-sync timestamp.
class AppSettings {
  AppSettings(this.db);
  final AppDatabase db;

  static const _autoSync = 'google_autosync';
  static const _lastSync = 'google_last_sync';
  static const _coachSeen = 'coach_seen';
  static const _saaraValue = 'saara_value';
  static const _ledgerFolder = 'ledger_sync_folder';
  static const _devices = 'known_devices';

  /// §9 Phase 3 — the folder Saara reads/writes its ledger file in, if the user
  /// set one. Null means device sync is manual (export/import). The path is not
  /// a secret; the passphrase that protects the files is, and lives in the OS
  /// keystore (see [AiConfigStore]-style secure storage), never here.
  Future<String?> ledgerFolder() => _read(_ledgerFolder);
  Future<void> setLedgerFolder(String? path) async {
    if (path == null || path.isEmpty) {
      await (db.delete(
        db.settings,
      )..where((s) => s.key.equals(_ledgerFolder))).go();
    } else {
      await _write(_ledgerFolder, path);
    }
  }

  Future<String?> _read(String key) async {
    final row = await (db.select(
      db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _write(String key, String value) => db
      .into(db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: Value(value)),
      );

  static const _mediaRetention = 'media_retention_days';
  static const _keptOverlaps = 'kept_overlaps';

  /// §8 overlaps the user has explicitly chosen to keep. An overlap is not an
  /// error — you can take a call while walking, or cook while a meeting runs in
  /// the background. Saara flags them once; if the user says "keep both", it
  /// stops raising that pair. Stored as `idA|idB` keys.
  Future<Set<String>> keptOverlaps() async {
    final raw = await _read(_keptOverlaps);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').where((s) => s.isNotEmpty).toSet();
  }

  Future<void> keepOverlap(String key) async {
    final all = await keptOverlaps()
      ..add(key);
    await _write(_keptOverlaps, all.join(','));
  }

  Future<void> unkeepOverlap(String key) async {
    final all = await keptOverlaps()
      ..remove(key);
    await _write(_keptOverlaps, all.join(','));
  }

  Future<bool> autoSyncEnabled() async => (await _read(_autoSync)) == 'on';
  Future<void> setAutoSync(bool on) => _write(_autoSync, on ? 'on' : 'off');

  /// §7.6 how long to keep photos/video/audio *after a task is completed*.
  /// null = keep forever (the default — never delete a user's media unasked).
  /// The raw image behind an AI extraction has already done its job once the
  /// fields are filled and the task is done, and media is what actually fills
  /// a phone, so this is the lever that keeps storage bounded.
  Future<int?> mediaRetentionDays() async {
    final v = await _read(_mediaRetention);
    if (v == null || v == 'never') return null;
    return int.tryParse(v);
  }

  Future<void> setMediaRetentionDays(int? days) =>
      _write(_mediaRetention, days == null ? 'never' : '$days');

  static const _archiveDir = 'media_archive_dir';

  /// §7.6 optional folder to **move** old media into instead of deleting it —
  /// an external drive, a NAS, or a desktop-synced cloud folder. Deliberately a
  /// plain filesystem path: it needs no OAuth scope, so it can't drag the app
  /// back into Google's restricted-scope (CASA) review. null = delete instead.
  Future<String?> archiveDir() async {
    final v = (await _read(_archiveDir))?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> setArchiveDir(String? path) =>
      _write(_archiveDir, path?.trim() ?? '');

  Future<DateTime?> lastSyncAt() async {
    final v = await _read(_lastSync);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> setLastSync(DateTime t) =>
      _write(_lastSync, t.toIso8601String());

  // ---- ledger sync timestamps (§9) -----------------------------------------
  // So the user can see exactly where each device stands: when this device last
  // exported its record, and — per other device — the export we last pulled in
  // and when. Together they answer "are my devices in sync?".

  static const _ledgerExportAt = 'ledger_export_at';
  static const _ledgerExportSig = 'ledger_export_sig';
  static const _ledgerImports =
      'ledger_imports'; // deviceId → {exportedAt, importedAt}

  Future<DateTime?> ledgerExportAt() async {
    final v = await _read(_ledgerExportAt);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> setLedgerExportAt(DateTime t) =>
      _write(_ledgerExportAt, t.toIso8601String());

  /// A hash of the *data* we last wrote out — so a pass re-writes (and re-uploads
  /// to the cloud folder) only when something actually changed, never on an idle
  /// heartbeat, and never in an echo after an idempotent merge.
  Future<String?> ledgerExportSig() => _read(_ledgerExportSig);
  Future<void> setLedgerExportSig(String sig) => _write(_ledgerExportSig, sig);

  /// deviceId → (the peer's `exportedAt` we last merged, when we merged it).
  Future<Map<String, ({DateTime exportedAt, DateTime importedAt})>>
  ledgerImports() async {
    final raw = await _read(_ledgerImports);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      final out = <String, ({DateTime exportedAt, DateTime importedAt})>{};
      m.forEach((k, v) {
        final e = DateTime.tryParse((v as Map)['exportedAt'].toString());
        final i = DateTime.tryParse(v['importedAt'].toString());
        if (e != null && i != null) {
          out[k] = (exportedAt: e, importedAt: i);
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  /// The `exportedAt` of the last file we merged from [deviceId] — so a pass can
  /// skip a peer file that hasn't changed since.
  Future<DateTime?> lastImportedExportOf(String deviceId) async =>
      (await ledgerImports())[deviceId]?.exportedAt;

  Future<void> recordLedgerImport(
    String deviceId,
    DateTime exportedAt,
    DateTime importedAt,
  ) async {
    final all = await ledgerImports();
    final next = {
      for (final e in all.entries)
        e.key: {
          'exportedAt': e.value.exportedAt.toIso8601String(),
          'importedAt': e.value.importedAt.toIso8601String(),
        },
      deviceId: {
        'exportedAt': exportedAt.toIso8601String(),
        'importedAt': importedAt.toIso8601String(),
      },
    };
    await _write(_ledgerImports, json.encode(next));
  }

  Future<bool> coachSeen() async => (await _read(_coachSeen)) == 'yes';
  Future<void> setCoachSeen() => _write(_coachSeen, 'yes');

  // ---- device registry (§9) ------------------------------------------------
  // Google can't tell you *which* of your devices made a task. The ledger can:
  // every entry carries the deviceId that wrote it. This registry maps those
  // ids to a human label ("Desktop", "Mobile") and travels in the sync bundle,
  // so each device learns the others' names — the "carries what Google can't"
  // idea, applied to provenance.

  /// A human label for *this* device, from its platform.
  String get thisDeviceLabel {
    if (Platform.isAndroid || Platform.isIOS) return 'Mobile';
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'Desktop';
    }
    return 'This device';
  }

  /// deviceId → label for every device we've heard of (self and peers).
  Future<Map<String, String>> knownDevices() async {
    final raw = await _read(_devices);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// Records this device's own id → label, so it appears in exports and its own
  /// UI. Idempotent.
  Future<void> registerThisDevice(String deviceId) =>
      learnDevices({deviceId: thisDeviceLabel});

  /// Merge freshly-heard device labels in (from an imported bundle, or self).
  Future<void> learnDevices(Map<String, String> devices) async {
    if (devices.isEmpty) return;
    final all = await knownDevices()
      ..addAll(devices);
    await _write(_devices, json.encode(all));
  }

  /// The label to show for a task created on [deviceId], from the perspective of
  /// [myDeviceId]. Null when the device is unknown (e.g. a Google-only import
  /// that never passed through the ledger).
  Future<String?> deviceLabel(String? deviceId, {String? myDeviceId}) async {
    if (deviceId == null || deviceId.isEmpty) return null;
    final label = (await knownDevices())[deviceId];
    if (deviceId == myDeviceId) return '${label ?? thisDeviceLabel} (this one)';
    return label;
  }

  /// §13 "Value by Saara" — a flat +1 each time Saara does the work (reads a
  /// task, runs a sync, auto-scores a result). Shows what the platform delivers.
  Future<int> saaraValue() async =>
      int.tryParse((await _read(_saaraValue)) ?? '0') ?? 0;
  Future<int> bumpSaaraValue([int by = 1]) async {
    final next = (await saaraValue()) + by;
    await _write(_saaraValue, '$next');
    return next;
  }
}
