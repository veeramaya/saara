import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';

import '../data/database.dart';
import '../domain/enums.dart';
import 'app_settings.dart';
import 'google/google_sync_service.dart';

/// §9 device-to-device sync through a **ledger file** — never through Google
/// (`docs/LEDGER_DESIGN.md`). Google carries interop with the outside world;
/// this carries Saara's own record between your devices.
///
/// The merge is conflict-free because the ledger is append-only: union the
/// entries, dedupe by id, and nothing is ever mutated. Task and area rows —
/// which *are* mutable — merge last-writer-wins on `updatedAt`. Importing the
/// same bundle twice changes nothing.
class LedgerSyncService {
  LedgerSyncService(this.db);
  final AppDatabase db;

  /// Bumped only if the bundle *shape* changes, independent of the DB schema.
  static const bundleFormat = 1;

  /// Serialise this device's record to a portable bundle.
  ///
  /// Everything needed to reconstruct and report on the other device travels:
  /// tasks (incl. soft-deleted and recurring rules), the ledger, and the areas
  /// and result definitions the entries are filed under. Health-sourced logs do
  /// **not** — they are a per-device projection of Health Connect, and merging
  /// them would resurrect values another device had replaced (§3.2).
  Future<Map<String, dynamic>> exportBundle() async {
    final tasks = await db.select(db.tasks).get();
    final entries = await db.select(db.taskTransitions).get();
    final areas = await db.select(db.areas).get();
    final results = await db.select(db.measurableResults).get();
    // Participants travel too, so a contact added on one device — with the
    // phone number to call/WhatsApp — is usable on the other (§9). This is the
    // only channel their number ever crosses; it never goes through Google.
    final participants = await db.select(db.taskParticipants).get();

    // Make sure this device names itself before exporting, so the other side
    // learns "Desktop"/"Mobile" for the entries we wrote.
    final settings = AppSettings(db);
    final deviceId = await db.deviceId();
    await settings.registerThisDevice(deviceId);

    return {
      'bundleFormat': bundleFormat,
      'schemaVersion': db.schemaVersion,
      'deviceId': deviceId,
      // When this snapshot was taken — a peer imports only when this is newer
      // than the last export it pulled from us (§9 timestamp-driven sync).
      'exportedAt': DateTime.now().toIso8601String(),
      'devices': await settings.knownDevices(),
      'tasks': [for (final t in tasks) t.toJson()],
      'ledger': [for (final e in entries) e.toJson()],
      'areas': [for (final a in areas) a.toJson()],
      'results': [for (final r in results) r.toJson()],
      'participants': [for (final p in participants) p.toJson()],
    };
  }

  Future<String> exportJson() async =>
      const JsonEncoder.withIndent('  ').convert(await exportBundle());

  // ---- encryption (§9) -----------------------------------------------------
  // The sync file often lands in a cloud folder (OneDrive, a synced SSD), so it
  // is encrypted with a passphrase the user sets. AES-256-CBC with a random IV
  // and salt, key stretched from the passphrase by PBKDF2-HMAC-SHA256. Losing
  // the passphrase means the file is unreadable — stated with the same
  // bluntness as Reset local data.

  static const _magic = 'SAARALEDGER1'; // format tag at the head of the file
  static const _pbkdfIterations = 100000;

  enc.Key _deriveKey(String passphrase, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdfIterations, 32));
    return enc.Key(
      derivator.process(Uint8List.fromList(utf8.encode(passphrase))),
    );
  }

  Uint8List _random(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
  }

  /// Export, encrypted with [passphrase]. The salt and IV travel in the clear at
  /// the head of the file (they must, to decrypt) — they are not secrets; the
  /// passphrase is.
  Future<String> exportEncrypted(String passphrase) async =>
      _encryptArmored(await exportJson(), passphrase);

  /// Encrypt [plain] into the armored `{magic,salt,iv,body}` envelope.
  String _encryptArmored(String plain, String passphrase) {
    final salt = _random(16);
    final iv = _random(16);
    final key = _deriveKey(passphrase, salt);
    final cipher = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final body = cipher.encrypt(plain, iv: enc.IV(iv));
    return json.encode({
      'magic': _magic,
      'salt': base64.encode(salt),
      'iv': base64.encode(iv),
      'body': body.base64,
    });
  }

  /// A stable hash of the *data* in [bundle] — ignoring the varying header
  /// (exportedAt, salt/iv, device list) and sorting rows by id — so identical
  /// data always hashes the same, even after an idempotent merge re-writes rows.
  String _dataSignature(Map<String, dynamic> bundle) {
    List<dynamic> sorted(String key) {
      final list = List<Map<String, dynamic>>.from(
        (bundle[key] as List? ?? const []).cast<Map<String, dynamic>>(),
      );
      list.sort(
        (a, b) =>
            (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? ''),
      );
      return list;
    }

    final data = {
      'tasks': sorted('tasks'),
      'ledger': sorted('ledger'),
      'areas': sorted('areas'),
      'results': sorted('results'),
      'participants': sorted('participants'),
    };
    return sha256.convert(utf8.encode(json.encode(data))).toString();
  }

  /// Import an encrypted bundle. Throws a clear error on the wrong passphrase or
  /// a corrupt file rather than merging garbage.
  // ---- watched folder (§9 Phase 3) ----------------------------------------

  /// The file this device writes. **Keyed by device id**, so two devices
  /// pointed at the same folder never write the same file — there is no write
  /// conflict to resolve, ever. If the folder happens to be a synced one
  /// (OneDrive, a shared SSD), propagation is automatic; Saara only ever does
  /// filesystem I/O and never talks to any cloud API (§1.4).
  String ownFileName(String deviceId) => 'saara-ledger-$deviceId.saara';

  /// Write this device's record to [dir], then merge every *other* device's
  /// file found there. [passphrase] protects all of them.
  ///
  /// A peer file that can't be read — wrong passphrase, half-written by a cloud
  /// client mid-download, corrupt — is skipped, not fatal. Sync should make
  /// progress on the files it *can* read rather than stall on one it can't.
  Future<FolderSyncResult> syncWatchedFolder(
    Directory dir,
    String passphrase,
  ) async {
    if (!await dir.exists()) {
      throw FileSystemException('Sync folder not found', dir.path);
    }
    final settings = AppSettings(db);
    final deviceId = await db.deviceId();
    final ownName = ownFileName(deviceId);
    final own = File('${dir.path}/$ownName');

    final result = FolderSyncResult();

    // Write our file **only when our data actually changed** since the last
    // write — so an idle heartbeat doesn't re-upload to the cloud folder, and an
    // idempotent merge doesn't echo a fresh export back at the peer.
    final bundle = await exportBundle();
    final sig = _dataSignature(bundle);
    if (await settings.ledgerExportSig() != sig) {
      final plain = const JsonEncoder.withIndent('  ').convert(bundle);
      await own.writeAsString(_encryptArmored(plain, passphrase));
      await settings.setLedgerExportSig(sig);
      await settings.setLedgerExportAt(DateTime.now());
      result.exported = true;
    }
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.saara')) continue;
      // Skip our own by *name*, not full path — path strings differ by slash
      // direction across platforms, and comparing them would let a device merge
      // its own file back in.
      if (name == ownName) continue;
      try {
        final bundle = decryptBundle(await entity.readAsString(), passphrase);
        final peerId = bundle['deviceId']?.toString();
        final exportedAt = DateTime.tryParse(
          bundle['exportedAt']?.toString() ?? '',
        );
        // Timestamp gate: skip a peer whose export hasn't changed since we last
        // pulled it — no wasted merge, and it's how "in sync" is detected.
        if (peerId != null && exportedAt != null) {
          final last = await settings.lastImportedExportOf(peerId);
          if (last != null && !exportedAt.isAfter(last)) {
            result.peersUpToDate++;
            continue;
          }
        }
        final merged = await importBundle(bundle);
        result.merged.add(merged);
        result.peersRead++;
        // importBundle records the import timestamp (used by the gate above).
      } catch (_) {
        result.peersSkipped++;
      }
    }
    return result;
  }

  /// The same pass as [syncWatchedFolder], but over Google Drive's hidden
  /// app-data folder instead of a local folder (§9). One file per device
  /// (`saara-ledger-<id>.saara`); write ours only when the data changed; import
  /// each peer whose export is newer than the last we pulled. Everything else —
  /// encryption, the signature gate, the timestamp gate — is shared.
  Future<FolderSyncResult> syncDrive(
    GoogleSyncService google,
    String passphrase,
  ) async {
    final settings = AppSettings(db);
    final deviceId = await db.deviceId();
    final ownName = ownFileName(deviceId);
    final files = await google.listAppData();
    final result = FolderSyncResult();

    // Write ours only if the data changed since last time.
    final bundle = await exportBundle();
    final sig = _dataSignature(bundle);
    if (await settings.ledgerExportSig() != sig) {
      final plain = const JsonEncoder.withIndent('  ').convert(bundle);
      String? existingId;
      for (final f in files) {
        if (f.name == ownName) {
          existingId = f.id;
          break;
        }
      }
      await google.uploadAppData(
        ownName,
        _encryptArmored(plain, passphrase),
        existingId: existingId,
      );
      await settings.setLedgerExportSig(sig);
      await settings.setLedgerExportAt(DateTime.now());
      result.exported = true;
    }

    // Import every *other* device's file, timestamp-gated.
    for (final f in files) {
      if (!f.name.endsWith('.saara') || f.name == ownName) continue;
      try {
        final peer = decryptBundle(
          await google.downloadAppData(f.id),
          passphrase,
        );
        final peerId = peer['deviceId']?.toString();
        final exportedAt = DateTime.tryParse(
          peer['exportedAt']?.toString() ?? '',
        );
        if (peerId != null && exportedAt != null) {
          final last = await settings.lastImportedExportOf(peerId);
          if (last != null && !exportedAt.isAfter(last)) {
            result.peersUpToDate++;
            continue;
          }
        }
        result.merged.add(await importBundle(peer));
        result.peersRead++;
      } catch (_) {
        result.peersSkipped++;
      }
    }
    return result;
  }

  Future<MergeSummary> importEncrypted(
    String armored,
    String passphrase,
  ) async => importBundle(decryptBundle(armored, passphrase));

  /// Decrypt an armored file to its bundle map — without merging. Lets a
  /// watched-folder pass read the header (deviceId, exportedAt) and decide
  /// whether the peer changed before doing the work.
  Map<String, dynamic> decryptBundle(String armored, String passphrase) {
    Map<String, dynamic> outer;
    try {
      outer = json.decode(armored) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('This is not a Saara ledger file.');
    }
    if (outer['magic'] != _magic) {
      throw const FormatException('This is not a Saara ledger file.');
    }
    final salt = base64.decode(outer['salt'] as String);
    final iv = base64.decode(outer['iv'] as String);
    final key = _deriveKey(passphrase, Uint8List.fromList(salt));
    final cipher = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    String plain;
    try {
      plain = cipher.decrypt64(
        outer['body'] as String,
        iv: enc.IV(Uint8List.fromList(iv)),
      );
    } catch (_) {
      throw const FormatException('Wrong passphrase, or the file is damaged.');
    }
    return json.decode(plain) as Map<String, dynamic>;
  }

  /// Merge a bundle from another device into this one. Idempotent.
  ///
  /// - **ledger** — append only. An entry we already hold (same id) is skipped;
  ///   nothing is updated. This is the whole reason merging can't conflict.
  /// - **areas / results / tasks** — last-writer-wins by `updatedAt`. A row we
  ///   don't have arrives; a row we both edited keeps the newer version. A
  ///   delete rides in as the losing/newer row carrying `deletedAt`.
  ///
  /// Foreign keys mean order matters: areas and results before tasks, tasks
  /// before ledger entries.
  Future<MergeSummary> importBundle(Map<String, dynamic> bundle) async {
    final summary = MergeSummary();
    final format = bundle['bundleFormat'] as int? ?? 0;
    if (format > bundleFormat) {
      throw StateError(
        'This ledger was written by a newer version of Saara ($format). '
        'Update this device before importing.',
      );
    }

    // Learn the peer's device names (and its view of others), so a task it
    // wrote shows "Desktop"/"Mobile" here too. Outside the transaction — it is
    // display metadata, never a reason to fail a merge.
    final incomingDevices = (bundle['devices'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );
    if (incomingDevices != null && incomingDevices.isNotEmpty) {
      await AppSettings(db).learnDevices(incomingDevices);
    }

    await db.transaction(() async {
      for (final j in (bundle['areas'] as List? ?? const [])) {
        final a = Area.fromJson(
          j as Map<String, dynamic>,
          serializer: _serializer,
        );
        if (await _isNewer(db.areas, a.id, a.updatedAt)) {
          await db.into(db.areas).insertOnConflictUpdate(a);
          summary.areas++;
        }
      }
      for (final j in (bundle['results'] as List? ?? const [])) {
        final r = MeasurableResult.fromJson(
          j as Map<String, dynamic>,
          serializer: _serializer,
        );
        if (await _isNewer(db.measurableResults, r.id, r.updatedAt)) {
          await db.into(db.measurableResults).insertOnConflictUpdate(r);
          summary.results++;
        }
      }
      // Tasks. An incoming task whose Google id already exists locally under a
      // *different* local id is the same real item imported from Google on both
      // devices (an invite, a pushed task). We do NOT add a second row — we fold
      // the incoming's Saara-only fields into the local one, and remember the id
      // mapping so its ledger entries attach to the right task (§9 unify).
      final idRemap = <String, String>{};
      for (final j in (bundle['tasks'] as List? ?? const [])) {
        final t = Task.fromJson(
          j as Map<String, dynamic>,
          serializer: _serializer,
        );
        final gcal = t.gcalEventId;
        if (gcal != null && gcal.isNotEmpty) {
          final twin = await db.taskDao.findByGcalEventIdExcept(gcal, t.id);
          if (twin != null) {
            idRemap[t.id] = twin.id;
            await _mergeSaaraFields(twin, t);
            summary.tasks++;
            continue;
          }
        }
        if (await _isNewer(db.tasks, t.id, t.updatedAt)) {
          await db.into(db.tasks).insertOnConflictUpdate(t);
          summary.tasks++;
        }
      }
      // Participants — carry the contact + its phone across. Remap the taskId
      // through the unify map so they land on the surviving task; skip any whose
      // task isn't here (FK safety).
      for (final j in (bundle['participants'] as List? ?? const [])) {
        var p = TaskParticipant.fromJson(
          j as Map<String, dynamic>,
          serializer: _serializer,
        );
        final mapped = idRemap[p.taskId];
        if (mapped != null) p = p.copyWith(taskId: mapped);
        if (!await _exists(db.tasks, p.taskId)) continue;
        await db.into(db.taskParticipants).insertOnConflictUpdate(p);
        summary.participants++;
      }
      // Ledger, append-only. Remap the taskId of any entry whose task was folded
      // into a local twin, so history lands on the surviving row.
      for (final j in (bundle['ledger'] as List? ?? const [])) {
        var e = TaskTransition.fromJson(
          j as Map<String, dynamic>,
          serializer: _serializer,
        );
        final mapped = idRemap[e.taskId];
        if (mapped != null) e = e.copyWith(taskId: mapped);
        if (!await _exists(db.taskTransitions, e.id)) {
          await db.into(db.taskTransitions).insert(e);
          summary.ledgerEntries++;
        }
      }
      // Area follows the ledger, not the mutable row (§4.3): after merging, set
      // each task's area from its latest correction, so a Google refresh — which
      // bumps updatedAt but writes no correction — can never overwrite a filing.
      await _applyLedgerAreas();
    });

    // Record when we pulled this peer's export, for the status panel and for the
    // watched-folder gate (skip a peer that hasn't changed since). Covers both
    // the manual import and the folder pass.
    final peerId = bundle['deviceId']?.toString();
    final exportedAt = DateTime.tryParse(
      bundle['exportedAt']?.toString() ?? '',
    );
    if (peerId != null && exportedAt != null) {
      await AppSettings(
        db,
      ).recordLedgerImport(peerId, exportedAt, DateTime.now());
    }
    return summary;
  }

  /// Fold an incoming task's fields into an existing local twin (same Google
  /// id). Two authorities meet here:
  ///
  /// - For a real **external invite** (a Calendar event someone else owns),
  ///   Google carries time/title/location faithfully to both devices, so the
  ///   newer copy wins by `updatedAt` and there is nothing special to do.
  /// - For a **Saara-owned** task that merely passed through Google **Tasks**,
  ///   Google is lossy: it can't hold a clock time, so it flattens the task to
  ///   a date (midnight UTC). The originating device still holds the true time.
  ///   A date-only value is therefore *never* authoritative for the time —
  ///   whichever copy carries a real time-of-day wins, regardless of which row
  ///   Google stamped more recently (its sync rewrites `updatedAt` on every
  ///   pull, which would otherwise let the lossy copy always "win").
  ///
  /// Area rides the ledger (`_applyLedgerAreas`) where a correction exists; here
  /// we only fill a gap so a task filed on one device doesn't show unfiled on
  /// its twin.
  Future<void> _mergeSaaraFields(Task local, Task incoming) async {
    final incomingNewer = incoming.updatedAt.isAfter(local.updatedAt);

    // Google Tasks flattens a timed task to a date at midnight UTC.
    bool dateOnly(DateTime? d) {
      if (d == null) return true;
      final u = d.toUtc();
      return u.hour == 0 &&
          u.minute == 0 &&
          u.second == 0 &&
          u.millisecond == 0;
    }

    DateTime? pickTime(DateTime? mine, DateTime? theirs) {
      final mineFlat = dateOnly(mine);
      final theirsFlat = dateOnly(theirs);
      // Their real time beats my date-only; my real time survives their date.
      if (mineFlat && !theirsFlat) return theirs;
      if (!mineFlat && theirsFlat) return mine;
      // Both the same nature → newer wins.
      return incomingNewer ? theirs : mine;
    }

    // The newest stamp wins so onward syncs carry the reconciled row forward,
    // even when we adopted the *older* row's real time.
    final newStamp = incomingNewer ? incoming.updatedAt : local.updatedAt;

    await (db.update(db.tasks)..where((t) => t.id.equals(local.id))).write(
      TasksCompanion(
        scheduledStart: Value(
          pickTime(local.scheduledStart, incoming.scheduledStart),
        ),
        dueDate: Value(pickTime(local.dueDate, incoming.dueDate)),
        // A timed appointment (event) outranks a plain to-do classification.
        kind: Value(
          incoming.kind == TaskKind.event ? TaskKind.event : local.kind,
        ),
        durationMin: Value(local.durationMin ?? incoming.durationMin),
        // Fill an unfiled gap only — a set area is owned by the ledger below.
        areaId: Value(local.areaId ?? incoming.areaId),
        // Fields where "newer wins" is simply right.
        title: Value(incomingNewer ? incoming.title : local.title),
        notes: Value(incomingNewer ? incoming.notes : local.notes),
        publicationState: Value(
          incomingNewer ? incoming.publicationState : local.publicationState,
        ),
        reminderOffsets: Value(
          incomingNewer ? incoming.reminderOffsets : local.reminderOffsets,
        ),
        reviewNotes: Value(
          incomingNewer ? incoming.reviewNotes : local.reviewNotes,
        ),
        geofenceEnabled: Value(
          incomingNewer ? incoming.geofenceEnabled : local.geofenceEnabled,
        ),
        lat: Value(incomingNewer ? incoming.lat : local.lat),
        lng: Value(incomingNewer ? incoming.lng : local.lng),
        priority: Value(incomingNewer ? incoming.priority : local.priority),
        updatedAt: Value(newStamp),
      ),
    );
  }

  /// Sets each task's area from its most recent `corrected` ledger entry. The
  /// ledger is append-only and merges conflict-free, so this is immune to the
  /// `updatedAt` races that plague the mutable row.
  Future<void> _applyLedgerAreas() async {
    final corrections = await db.taskDao.allCorrections();
    final latest = <String, TaskTransition>{};
    for (final c in corrections) {
      final seen = latest[c.taskId];
      if (seen == null || c.at.isAfter(seen.at)) latest[c.taskId] = c;
    }
    for (final entry in latest.entries) {
      await (db.update(db.tasks)..where((t) => t.id.equals(entry.key))).write(
        TasksCompanion(areaId: Value(entry.value.areaId)),
      );
    }
  }

  Future<MergeSummary> importJson(String jsonStr) =>
      importBundle(json.decode(jsonStr) as Map<String, dynamic>);

  /// True when a file's contents are an encrypted Saara bundle (vs a plain one).
  bool isEncrypted(String content) {
    try {
      final m = json.decode(content);
      return m is Map && m['magic'] == _magic;
    } catch (_) {
      return false;
    }
  }

  /// Import a file whether it is encrypted or plain — the common case (a manual
  /// transfer between your own devices) needs no passphrase at all. Only a file
  /// that was deliberately protected asks for one.
  Future<MergeSummary> importFile(String content, {String? passphrase}) async {
    if (isEncrypted(content)) {
      if (passphrase == null || passphrase.isEmpty) {
        throw const FormatException(
          'This file is password-protected. Enter its password to import.',
        );
      }
      return importEncrypted(content, passphrase);
    }
    return importJson(content);
  }

  /// True when we don't have [id], or the incoming [incoming] stamp is *strictly*
  /// newer than ours — the last-writer-wins test.
  ///
  /// Strictly newer, not `>=`, so a re-import is a genuine no-op: an equal
  /// timestamp means we already hold an equally-recent version and rewriting it
  /// would only inflate the merge count. (Two devices editing the same row in
  /// the same millisecond is the one case this leaves unconverged — negligible
  /// at millisecond precision, and the ledger itself, which is append-only,
  /// converges regardless.)
  Future<bool> _isNewer(
    TableInfo<Table, dynamic> table,
    String id,
    DateTime incoming,
  ) async {
    final row =
        await (db.selectOnly(table)
              ..addColumns([table.$columns.firstWhere((c) => c.name == 'id')])
              ..addColumns([
                table.$columns.firstWhere((c) => c.name == 'updated_at'),
              ])
              ..where(
                table.$columns.firstWhere((c) => c.name == 'id').equals(id),
              ))
            .getSingleOrNull();
    if (row == null) return true;
    final mine = row.read(
      table.$columns.firstWhere((c) => c.name == 'updated_at')
          as GeneratedColumn<DateTime>,
    );
    return mine == null || incoming.isAfter(mine);
  }

  Future<bool> _exists(TableInfo<Table, dynamic> table, String id) async {
    final row =
        await (db.selectOnly(table)
              ..addColumns([table.$columns.firstWhere((c) => c.name == 'id')])
              ..where(
                table.$columns.firstWhere((c) => c.name == 'id').equals(id),
              ))
            .getSingleOrNull();
    return row != null;
  }
}

/// Coerces JSON back into Drift rows, fixing the one thing the default
/// deserializer gets wrong here: a `List<int>` column (e.g. `reminderOffsets`)
/// comes out of `jsonDecode` as `List<dynamic>`, and Drift's plain cast to
/// `List<int>?` throws. We rebuild it as a real `List<int>`. Everything else is
/// left to the default serializer.
class _BundleSerializer extends ValueSerializer {
  const _BundleSerializer();
  static const _base = ValueSerializer.defaults();

  @override
  dynamic toJson<T>(T value) => _base.toJson<T>(value);

  @override
  T fromJson<T>(dynamic json) {
    if (json is List) {
      // Every list column in the exported tables is a List<int>.
      return json.map((e) => e as int).toList() as T;
    }
    return _base.fromJson<T>(json);
  }
}

const _serializer = _BundleSerializer();

/// What a merge changed — shown back to the user, and asserted in tests.
class MergeSummary {
  int tasks = 0;
  int ledgerEntries = 0;
  int areas = 0;
  int results = 0;
  int participants = 0;

  int get total => tasks + ledgerEntries + areas + results + participants;
  bool get isEmpty => total == 0;

  void add(MergeSummary other) {
    tasks += other.tasks;
    ledgerEntries += other.ledgerEntries;
    areas += other.areas;
    results += other.results;
    participants += other.participants;
  }

  @override
  String toString() =>
      'Merged $tasks task${tasks == 1 ? '' : 's'}, '
      '$ledgerEntries ledger entr${ledgerEntries == 1 ? 'y' : 'ies'}, '
      '$areas area${areas == 1 ? '' : 's'}, '
      '$results result${results == 1 ? '' : 's'}';
}

/// The outcome of one watched-folder pass: what merged, and how many peer files
/// were read versus skipped (unreadable / mid-download / wrong passphrase).
class FolderSyncResult {
  final MergeSummary merged = MergeSummary();
  int peersRead = 0;
  int peersSkipped = 0;
  int peersUpToDate = 0; // a peer whose export hadn't changed since last time
  bool exported = false; // did this pass re-write our own file (data changed)?

  @override
  String toString() {
    if (peersRead == 0 && peersSkipped == 0 && peersUpToDate == 0) {
      return 'Saved. No other device has written here yet.';
    }
    final parts = <String>[
      if (merged.isEmpty) 'Already up to date' else merged.toString(),
    ];
    if (peersSkipped > 0) {
      parts.add(
        '$peersSkipped file${peersSkipped == 1 ? '' : 's'} skipped '
        '(unreadable or still downloading)',
      );
    }
    return parts.join(' · ');
  }
}
