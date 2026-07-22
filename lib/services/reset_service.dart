import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/data_dir.dart';
import '../data/database.dart';
import '../data/seed/default_areas.dart';

/// §1.1 "Reset local data" — wipes everything Saara holds **on this device**.
///
/// The honest framing matters more than the mechanics here. Saara is
/// local-first, so a reset is not "log out and pull it back down": some of the
/// most valuable data has no copy anywhere else.
///
/// **Comes back** on the next Google sync: tasks and events that were synced.
///
/// **Gone for good** — these are local-only by design (§1.4) and Realmaya holds
/// no copy: the integrity ledger (every start/complete/miss ever recorded),
/// captures (photos, audio, video), private event review notes, areas and
/// measurable results, and anything never synced to Google.
///
/// Which is why the UI offers Export first and says so plainly.
class ResetService {
  ResetService(this.db);
  final AppDatabase db;

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Deletes every row, every captured file, and every stored credential, then
  /// re-seeds the starter areas so the app opens in a usable first-run state.
  ///
  /// Rows are cleared child-first so foreign keys never block the wipe.
  Future<void> wipeLocalData() async {
    await db.transaction(() async {
      // Children before parents (FKs are enforced — see beforeOpen).
      await db.delete(db.measurableLogs).go();
      await db.delete(db.taskTransitions).go();
      await db.delete(db.taskParticipants).go();
      await db.delete(db.captures).go();
      await db.delete(db.listenerFeedbacks).go();
      await db.delete(db.tasks).go();
      await db.delete(db.measurableResults).go();
      await db.delete(db.committedListeners).go();
      await db.delete(db.saaraGroups).go();
      await db.delete(db.dayLogs).go();
      await db.delete(db.healthSnapshots).go();
      await db.delete(db.areas).go();
      await db.delete(db.settings).go();
      await db.delete(db.apiCredentials).go();
    });

    // Captured media lives on the filesystem, not in the database.
    try {
      final base = await saaraDataDir();
      final captures = Directory('${base.path}/captures');
      if (await captures.exists()) {
        await captures.delete(recursive: true);
      }
    } catch (_) {
      // A locked or missing file must not leave the reset half-done.
    }

    // API keys and Google tokens live in the OS keystore, never the database.
    try {
      await _secure.deleteAll();
    } catch (_) {}

    // Leave the app in a usable first-run state rather than an empty shell —
    // the starter areas are scaffolding, not user data.
    await _seedDefaultAreas();
  }

  Future<void> _seedDefaultAreas() async {
    final now = DateTime.now();
    await db.batch((b) {
      for (final a in kDefaultAreas) {
        b.insert(
          db.areas,
          AreasCompanion.insert(
            id: a.id,
            baseCategory: a.baseCategory,
            displayName: a.displayName,
            icon: Value(a.icon),
            color: Value(a.color),
            sortOrder: Value(a.sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });
  }
}
