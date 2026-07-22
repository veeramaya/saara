import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import 'tasks.dart';

/// §3.3 TaskParticipant — on-device contact refs only; never uploaded (§1.4).
class TaskParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get contactLookupKey => text()();
  TextColumn get displayName => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// §3.3 TaskTransition — **the integrity ledger.** One row per status change
/// (§4). Reports are computed from these rows, never from mutable task state.
/// A `rescheduled` transition's `note` links to the new task instance (§4).
/// §3.3 **the ledger.** Append-only: entries are never updated or deleted, so
/// merging two devices is a union deduped by [id] — there is no conflict to
/// resolve, because nothing mutates. See `docs/LEDGER_DESIGN.md`.
///
/// Entries are **self-contained**: each carries the area and title *as they were
/// at that moment*, exactly as an accounting posting records the account code
/// rather than a pointer that can be re-classified later. Reclassifying a task
/// tomorrow must not silently rewrite what last month's report said — and
/// another device must be able to read this ledger without also holding our
/// `tasks` table.
///
/// The atom is one task or **one occurrence** of an event, never a series
/// (§3.2a). Every aggregate above it is derived.
class TaskTransitions extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();

  /// What this entry records — a status move, or creation / release / deletion
  /// / correction. Defaults to `statusChange` so pre-existing rows read
  /// correctly.
  TextColumn get kind =>
      textEnum<LedgerEventKind>().withDefault(
        Constant('statusChange'),
      )();

  /// The status **in force after this entry**. For a `statusChange` that is the
  /// state moved into; for `released`, `deleted` or `corrected` the lifecycle
  /// did not move, so it records the status still standing at that moment.
  ///
  /// Kept non-nullable on purpose: making it nullable would mean rewriting the
  /// table on live data via Drift's experimental `TableMigration`, and always
  /// recording the status in force is informative rather than misleading.
  TextColumn get fromStatus => textEnum<TaskStatus>().nullable()();
  TextColumn get toStatus => textEnum<TaskStatus>()();

  /// The area in force **at this moment** — after the change, for a correction.
  TextColumn get areaId => text().nullable()();

  /// For `corrected`: the area it was moved *from*, so the adjustment is legible
  /// on its own ("Health → Entertainment").
  TextColumn get fromAreaId => text().nullable()();

  /// The title as it read then, so another device can report on this entry
  /// without holding the task row.
  TextColumn get titleSnapshot => text().nullable()();

  /// Which device witnessed it. Provenance survives merging.
  TextColumn get deviceId => text().nullable()();

  /// Optional, user-supplied, never required and never scored — kept because
  /// noticing *"I keep filing entertainment under health"* is worth learning
  /// from (§4.4). Shown back only to its author.
  TextColumn get reason => text().nullable()();

  DateTimeColumn get at => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
