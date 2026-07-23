import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';

import '../data/database.dart';

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

    return {
      'bundleFormat': bundleFormat,
      'schemaVersion': db.schemaVersion,
      'deviceId': await db.deviceId(),
      'tasks': [for (final t in tasks) t.toJson()],
      'ledger': [for (final e in entries) e.toJson()],
      'areas': [for (final a in areas) a.toJson()],
      'results': [for (final r in results) r.toJson()],
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
  Future<String> exportEncrypted(String passphrase) async {
    final salt = _random(16);
    final iv = _random(16);
    final key = _deriveKey(passphrase, salt);
    final cipher = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final body = cipher.encrypt(await exportJson(), iv: enc.IV(iv));
    return json.encode({
      'magic': _magic,
      'salt': base64.encode(salt),
      'iv': base64.encode(iv),
      'body': body.base64,
    });
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
    final deviceId = await db.deviceId();
    final ownName = ownFileName(deviceId);
    final own = File('${dir.path}/$ownName');

    // Write our own file first, so the other device sees our latest.
    await own.writeAsString(await exportEncrypted(passphrase));

    final result = FolderSyncResult();
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.saara')) continue;
      // Skip our own by *name*, not full path — path strings differ by slash
      // direction across platforms, and comparing them would let a device merge
      // its own file back in.
      if (name == ownName) continue;
      try {
        final merged = await importEncrypted(
          await entity.readAsString(),
          passphrase,
        );
        result.merged.add(merged);
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
  ) async {
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
    return importJson(plain);
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
      for (final j in (bundle['tasks'] as List? ?? const [])) {
        final t = Task.fromJson(
          j as Map<String, dynamic>,
          serializer: _serializer,
        );
        if (await _isNewer(db.tasks, t.id, t.updatedAt)) {
          await db.into(db.tasks).insertOnConflictUpdate(t);
          summary.tasks++;
        }
      }
      for (final j in (bundle['ledger'] as List? ?? const [])) {
        final e = TaskTransition.fromJson(
          j as Map<String, dynamic>,
          serializer: _serializer,
        );
        if (!await _exists(db.taskTransitions, e.id)) {
          await db.into(db.taskTransitions).insert(e);
          summary.ledgerEntries++;
        }
      }
    });
    return summary;
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

  int get total => tasks + ledgerEntries + areas + results;
  bool get isEmpty => total == 0;

  void add(MergeSummary other) {
    tasks += other.tasks;
    ledgerEntries += other.ledgerEntries;
    areas += other.areas;
    results += other.results;
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

  @override
  String toString() {
    if (peersRead == 0 && peersSkipped == 0) {
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
