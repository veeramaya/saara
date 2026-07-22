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

  Future<bool> coachSeen() async => (await _read(_coachSeen)) == 'yes';
  Future<void> setCoachSeen() => _write(_coachSeen, 'yes');

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
