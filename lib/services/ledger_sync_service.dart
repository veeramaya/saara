import 'dart:convert';

import 'package:drift/drift.dart';

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
        final a = Area.fromJson(j as Map<String, dynamic>);
        if (await _isNewer(db.areas, a.id, a.updatedAt)) {
          await db.into(db.areas).insertOnConflictUpdate(a);
          summary.areas++;
        }
      }
      for (final j in (bundle['results'] as List? ?? const [])) {
        final r = MeasurableResult.fromJson(j as Map<String, dynamic>);
        if (await _isNewer(db.measurableResults, r.id, r.updatedAt)) {
          await db.into(db.measurableResults).insertOnConflictUpdate(r);
          summary.results++;
        }
      }
      for (final j in (bundle['tasks'] as List? ?? const [])) {
        final t = Task.fromJson(j as Map<String, dynamic>);
        if (await _isNewer(db.tasks, t.id, t.updatedAt)) {
          await db.into(db.tasks).insertOnConflictUpdate(t);
          summary.tasks++;
        }
      }
      for (final j in (bundle['ledger'] as List? ?? const [])) {
        final e = TaskTransition.fromJson(j as Map<String, dynamic>);
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

/// What a merge changed — shown back to the user, and asserted in tests.
class MergeSummary {
  int tasks = 0;
  int ledgerEntries = 0;
  int areas = 0;
  int results = 0;

  int get total => tasks + ledgerEntries + areas + results;
  bool get isEmpty => total == 0;

  @override
  String toString() =>
      'Merged $tasks task${tasks == 1 ? '' : 's'}, '
      '$ledgerEntries ledger entr${ledgerEntries == 1 ? 'y' : 'ies'}, '
      '$areas area${areas == 1 ? '' : 's'}, '
      '$results result${results == 1 ? '' : 's'}';
}
